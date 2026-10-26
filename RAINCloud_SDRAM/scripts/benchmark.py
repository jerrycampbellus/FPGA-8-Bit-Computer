"""Measure FPGA throughput by logical request size; overwrites selected SDRAM.

Uses hardware counters, not JTAG elapsed time. No programming or mock fallback.
Also checks byte/cache/page application requests with per-word byte enables.
"""
import argparse
from dataclasses import asdict
from datetime import datetime
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'host'))
from sdram_client import Tester, Configuration, SystemConsoleTransport


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--system-console', default='system-console')
    parser.add_argument('--report', default=str(ROOT / 'build/benchmark.json'))
    args = parser.parse_args()
    report = dict(transport='jtag', recorded_at=datetime.now().astimezone().isoformat(),
                  complete=False, cases=[], application_requests=[])
    try:
        with SystemConsoleTransport(args.system_console, timeout=40) as link:
            tester = Tester(link)
            report['identity'] = tester.identify()
            if tester.status()['busy']:
                raise RuntimeError('Tester is already running; benchmark did not change it')
            try:
                for start in (0, 0x7fe):
                    for burst in (1, 4, 8, 16, 32, 64, 128, 256, 512, 1024):
                        cfg = Configuration(start=start, words=65536, repeats=3, pattern=2, burst=burst)
                        tester.configure(cfg)
                        result = tester.wait(timeout=60, run_id=tester.start())
                        assert result['done'] and not result['failed'] and not result['stopped'], result
                        assert result['operations'] == cfg.words * cfg.repeats * 2, result
                        report['cases'].append(dict(configuration=asdict(cfg), result=result))
                        print(f'{start:#06x} / {burst:4} words: {result["bytes_per_second"]/1e6:.3f} MB/s, {result["error_count"]} errors', flush=True)
                for count in (1, 16, 1024, 3):
                    address = 0x7fe
                    tester.write(address, [0x1234]*count)
                    before = tester.status()['run_id']
                    masks = [i % 4 for i in range(count)]
                    result = tester.write(address, [0xabcd]*count, byte_enables=masks)
                    assert result['run_id'] == before+1 and result['operations'] == count
                    assert tester.read(address, count) == [[0x1234, 0x12cd, 0xab34, 0xabcd][m] for m in masks]
                    report['application_requests'].append(dict(words=count, address=address, per_word_masks='pass', single_write_request=True))
                    print(f'PASS application request: {count} words, per-word masks', flush=True)
            finally:
                # Release only when idle; never interrupt another run to clean up.
                if not tester.status()['busy']:
                    tester.release()
                    report['final_status'] = tester.status()
            report['complete'] = True
    except Exception as exc:
        report['error'] = str(exc)
        raise
    finally:
        Path(args.report).parent.mkdir(parents=True, exist_ok=True)
        Path(args.report).write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')


if __name__ == '__main__':
    main()
