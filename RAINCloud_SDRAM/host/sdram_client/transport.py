"""Register transport boundary; application code has no Quartus dependency."""
from pathlib import Path
import queue
import re
import subprocess
import threading
import time
from collections import deque
from typing import Protocol

class TransportError(RuntimeError):
    pass

class Transport(Protocol):
    def read32(self, address: int, count: int = 1) -> list[int]: ...
    def write32(self, address: int, values: list[int]) -> None: ...
    def close(self) -> None: ...

class SystemConsoleTransport:
    def __init__(self, executable='system-console', *, timeout=20.0, service_index=None):
        self.timeout = timeout
        self.executable = str(executable)
        self.service_index = service_index
        self._id = 0
        self._lock = threading.Lock()
        self._process = None
        self.connect()

    def connect(self):
        self.close()
        script = Path(__file__).resolve().parents[1] / 'bridge.tcl'
        script_path = script.as_posix()
        if any(ch in script_path for ch in '{}\r\n'):
            raise ValueError('Tcl adapter path contains unsupported characters')
        self._lines = queue.Queue()
        self.diagnostics = deque(maxlen=30)
        self._process = subprocess.Popen(
            [self.executable, '--cli'],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, bufsize=1, encoding='utf-8', errors='replace',
            creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        process, lines = self._process, self._lines
        def reader():
            for line in process.stdout:
                self.diagnostics.append(line.rstrip())
                lines.put(line.rstrip())
            lines.put(None)
        threading.Thread(target=reader, daemon=True).start()
        try:
            # --script shuts System Console's service executor down at script end.
            # Source into the persistent CLI interpreter instead.
            process.stdin.write('source {' + script_path + '}\n')
            process.stdin.flush()
            deadline = time.monotonic() + self.timeout
            while True:
                try:
                    line = lines.get(timeout=max(0, deadline-time.monotonic()))
                except queue.Empty as exc:
                    raise TransportError('System Console adapter startup timed out') from exc
                if line is None:
                    raise TransportError('System Console exited during startup')
                if '@0 OK ready' in line:
                    break
            self._exchange('C ' + ('auto' if self.service_index is None else str(int(self.service_index))))
        except Exception:
            self.close()
            raise

    def _exchange(self, command):
        with self._lock:
            self._id += 1
            request_id = self._id
            try:
                self._process.stdin.write(f'sdram_rpc {request_id} {command}\n')
                self._process.stdin.flush()
            except (OSError, ValueError, AttributeError) as exc:
                raise TransportError('System Console is disconnected') from exc
            deadline = time.monotonic() + self.timeout
            while True:
                try:
                    line = self._lines.get(timeout=max(0, deadline-time.monotonic()))
                except queue.Empty as exc:
                    # Do not retry mutations after ambiguous delivery.
                    detail = ' | '.join(list(getattr(self, 'diagnostics', []))[-4:])
                    raise TransportError('System Console timeout; reconnect and inspect status/acknowledgement. ' + detail) from exc
                if line is None:
                    raise TransportError('System Console exited')
                match = re.search(r'@(\d+) (OK|ERR)(?: (.*))?$', line)
                if match and int(match[1]) == request_id:
                    if match[2] == 'ERR':
                        raise TransportError(match[3])
                    return match[3] or ''

    @staticmethod
    def _validate(address, count):
        if type(address) is not int or type(count) is not int or address % 4 or not 1 <= count <= 1024:
            raise ValueError('Invalid register address/count')
        end = address + 4*count
        if not (0 <= address < end <= 0x200 or 0x1000 <= address < end <= 0x2000):
            raise ValueError('Register access outside control bank or page staging window')

    def read32(self, address, count=1):
        self._validate(address, count)
        words = []
        for offset in range(0, count, 128):
            size = min(128, count-offset)
            reply = self._exchange(f'R {address+4*offset} {size}')
            try:
                chunk = [int(word, 0) for word in reply.split()]
            except ValueError as exc:
                raise TransportError('Malformed read response') from exc
            if len(chunk) != size or any(not 0 <= word <= 0xffffffff for word in chunk):
                raise TransportError('Read length/value mismatch')
            words.extend(chunk)
        return words

    def write32(self, address, values):
        self._validate(address, len(values))
        if any(not isinstance(v, int) or not 0 <= v <= 0xffffffff for v in values):
            raise ValueError('Expected unsigned 32-bit values')
        for offset in range(0, len(values), 128):
            chunk = values[offset:offset+128]
            self._exchange(f'W {address+4*offset} {len(chunk)} ' + ' '.join(map(str, chunk)))

    def close(self):
        process = self._process
        if process is not None:
            if process.poll() is None:
                try:
                    process.stdin.close()
                    process.wait(timeout=2)
                except (OSError, subprocess.TimeoutExpired):
                    process.kill()
                    process.wait(timeout=5)
            if process.stdout:
                process.stdout.close()
            self._process = None

    def __enter__(self): return self
    def __exit__(self, *args): self.close()
