from dataclasses import dataclass, astuple
import time
from .transport import Transport

@dataclass(frozen=True)
class Configuration:
    start: int = 0
    words: int = 1024
    repeats: int = 1
    pattern: int = 2
    seed: int = 0x12345678
    burst: int = 1024
    flags: int = 0
    gap: int = 0

    def validate(self):
        if any(type(v) is not int or not 0 <= v <= 0xffffffff for v in astuple(self)):
            raise ValueError('Configuration fields must be unsigned 32-bit integers')
        if self.start % 2 or self.words < 1 or self.start + 2*self.words > 0x4000000:
            raise ValueError('Range must contain aligned 16-bit words within 64 MiB')
        if not self.repeats or not 0 <= self.pattern <= 6 or not 1 <= self.burst <= 1024 or self.flags > 3:
            raise ValueError('Invalid repeat count, pattern, burst, or stall flags')

class Tester:
    def __init__(self, transport: Transport, *, timeout=5.0):
        self.transport = transport
        self.timeout = timeout
        self.identify()

    def _read(self, address): return self.transport.read32(address)[0]
    def identify(self):
        magic, version, build, capabilities = self.transport.read32(0, 4)
        if magic != 0x5344524d or version >> 16 != 1:
            raise RuntimeError(f'Unsupported SDRAM tester: magic={magic:08x}, API={version:08x}')
        self.identity = dict(api=version, build_id=f'{build:08x}', capabilities=capabilities,
                             clock_hz=self._read(0x1c))
        self.max_words = self._read(0x58) if capabilities & 0x80 else 16
        self.staging_base = self._read(0x5c) if capabilities & 0x80 else 0x100
        if not 1 <= self.max_words <= 1024 or self.staging_base != (0x1000 if capabilities & 0x80 else 0x100):
            raise RuntimeError('Unsupported staging capability')
        self.identity.update(max_transfer_words=self.max_words, staging_base=self.staging_base)
        return self.identity

    @staticmethod
    def decode_status(value):
        return {name: bool(value & (1 << bit)) for bit, name in
                [(1,'busy'), (2,'done'), (3,'stopped'), (4,'initialized'),
                 (5,'owner'), (6,'failed'), (7,'stop_pending')]}

    def status(self):
        return dict(self.identity, **self.decode_status(self._read(0x10)),
                    run_id=self._read(0x50), ack=self._read(0x14),
                    command_error=self._read(0x18), refresh_count=self._read(0x48),
                    display=self._read(0x54))

    def command(self, opcode):
        previous = self._read(0x14)
        command = ((((previous >> 8) + 1) & 0xffffff) << 8) | opcode
        self.transport.write32(0x14, [command])
        deadline = time.monotonic() + self.timeout
        while self._read(0x14) != command:
            if time.monotonic() >= deadline:
                raise TimeoutError('Command acknowledgement timed out; inspect status before retrying')
            time.sleep(.001)
        error = self._read(0x18)
        if error:
            raise RuntimeError({1:'Tester busy', 2:'Invalid configuration or not initialized',
                                3:'Host does not own tester', 4:'Unknown command'}.get(error, f'Command error {error}'))
        return command

    def claim(self): self.command(6)
    def release(self): self.command(7)
    def configure(self, config: Configuration):
        config.validate()
        if config.burst > self.max_words:
            raise ValueError(f'Firmware supports at most {self.max_words} words per request')
        self.claim()
        if self.status()['busy']: raise RuntimeError('Tester busy')
        values = list(astuple(config))
        self.transport.write32(0x20, values)
        if self.transport.read32(0x20, 8) != values:
            raise RuntimeError('Configuration readback mismatch')
        return config

    def configuration(self): return Configuration(*self.transport.read32(0x20, 8))
    def start(self): self.command(1); return self._read(0x50)
    def stop(self): self.command(2)
    def results(self):
        self.command(3)
        generation = self._read(0x4c)
        s = self.transport.read32(0x80, 16)
        log = self.transport.read32(0x180, 16)
        if self._read(0x4c) != generation:
            raise RuntimeError('Snapshot replaced by another client; use a single host writer')
        cycles = s[5] | (s[6] << 32)
        byte_count = s[3] | (s[4] << 32)
        seconds = cycles / self.identity['clock_hz']
        return dict(self.identity, snapshot_id=generation, run_id=s[0], **self.decode_status(s[1]),
                    operations=s[2] | (s[11] << 32), bytes=byte_count, cycles=cycles, seconds=seconds,
                    bytes_per_second=byte_count/seconds if seconds else 0,
                    error_count=s[7], first_error_address=s[8], expected=s[9] >> 16,
                    actual=s[9] & 0xffff, refresh_count=s[12],
                    start=s[13], words=s[14], pattern=s[15],
                    errors=[dict(address=log[2*i], expected=log[2*i+1] >> 16,
                                 actual=log[2*i+1] & 0xffff) for i in range(min(s[10],8))])

    def wait(self, *, timeout=30.0, run_id=None):
        deadline = time.monotonic() + timeout
        while self._read(0x10) & 2:
            if time.monotonic() >= deadline:
                raise TimeoutError('Run still active; use stop for a controlled stop')
            time.sleep(.01)
        result = self.results()
        if run_id is not None and result['run_id'] != run_id:
            raise RuntimeError('Run changed while waiting')
        return result

    @staticmethod
    def _range(address, words, max_words=1024):
        if type(address) is not int or type(words) is not int or address < 0 or address % 2 or not 1 <= words <= max_words or address+2*words > 0x4000000:
            raise ValueError(f'Staging operations require 1..{max_words} aligned words within 64 MiB')

    def _direct(self, address, count, opcode):
        self.transport.write32(0x40, [address,count])
        self.command(opcode)
        result = self.wait(run_id=self._read(0x50))
        if result['failed'] or result['stopped']: raise RuntimeError('Memory operation did not complete successfully')
        return result

    def read(self, address, words=1):
        self._range(address,words,self.max_words)
        self.claim()
        if self.status()['busy']: raise RuntimeError('Tester busy')
        self._direct(address,words,4)
        return [v & 0xffff for v in self.transport.read32(self.staging_base,words)]

    def write(self, address, data, *, byte_enable=3, byte_enables=None):
        """One request with a uniform mask, or one byte_enables mask per word.

        Bit 0 enables the low byte, bit 1 the high byte. Per-word masks override
        the uniform default; all input is validated before ownership or writes.
        Request size/masks never change the physical SDRAM mode register.
        """
        self._range(address,len(data),self.max_words)
        if type(byte_enable) is not int or not 0 <= byte_enable <= 3 or any(type(v) is not int or not 0 <= v <= 0xffff for v in data):
            raise ValueError('Expected 16-bit data and two byte-enable bits')
        masks = [byte_enable]*len(data) if byte_enables is None else list(byte_enables)
        if len(masks) != len(data) or any(type(v) is not int or not 0 <= v <= 3 for v in masks):
            raise ValueError('Expected one two-bit byte-enable mask per word')
        self.claim()
        if self.status()['busy']: raise RuntimeError('Tester busy')
        self.transport.write32(self.staging_base,[v | (mask<<16) for v,mask in zip(data,masks)])
        return self._direct(address,len(data),5)

    @staticmethod
    def _page_address(address):
        if type(address) is not int or address < 0 or address % 2048 or address + 2048 > 0x4000000:
            raise ValueError('Page address must be 2 KiB aligned within 64 MiB')

    def read_page(self, address):
        """Read one aligned 2 KiB page as bytes, little-endian within each word."""
        self._page_address(address)
        return b''.join(word.to_bytes(2, 'little') for word in self.read(address, 1024))

    def write_page(self, address, data):
        """Write exactly 2048 bytes in one FPGA request; no automatic retry."""
        self._page_address(address)
        if not isinstance(data, (bytes, bytearray, memoryview)):
            raise ValueError('Page data must contain exactly 2048 bytes')
        data = bytes(data)
        if len(data) != 2048:
            raise ValueError('Page data must contain exactly 2048 bytes')
        return self.write(address, [int.from_bytes(data[i:i+2], 'little') for i in range(0, 2048, 2)])

