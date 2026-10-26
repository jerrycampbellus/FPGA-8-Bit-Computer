"""Run against an already programmed board. Destructively tests its volatile SDRAM.
No FPGA programming, flash writes or model fallback is performed by this script.
"""
import argparse
import json
from pathlib import Path
import sys
import time

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'host'))
from sdram_client import Tester, Configuration, SystemConsoleTransport

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--system-console',default='system-console')
    parser.add_argument('--full',action='store_true',help='Also test the complete 64 MiB address range')
    parser.add_argument('--report',default=str(ROOT/'build'/'hardware-page-results.json'))
    args=parser.parse_args()
    report={'transport':'jtag','cases':[],'complete':False}
    link=None
    def connect():
        new=SystemConsoleTransport(args.system_console,timeout=40)
        return new,Tester(new)
    try:
        link,tester=connect()
        report['identity']=tester.identify()
        assert tester.max_words==1024,'Page-capable firmware is required'
        print('Connected: '+json.dumps(report['identity']),flush=True)
        for pattern in range(7):
            print(f'Running pattern {pattern}',flush=True)
            cfg=Configuration(start=0x7f0,words=1025,repeats=2,pattern=pattern,flags=3,gap=50000)
            tester.configure(cfg)
            result=tester.wait(timeout=30,run_id=tester.start())
            assert result['done'] and not result['failed'] and not result['stopped'],result
            assert result['operations']==1025*2*(7 if pattern==6 else 2),result
            report['cases'].append(result)
            print(f'PASS pattern {pattern}: {result["operations"]} operations, {result["error_count"]} errors',flush=True)
        for address in (0,0x7fe,0xfffffe,0x1fffffe,0x2fffffe,0x3ffffe0):
            tester.write(address,[0x1234,0xabcd])
            tester.write(address,[0xffff,0xffff],byte_enable=1)
            assert tester.read(address,2)==[0x12ff,0xabff],hex(address)
            tester.write(address,[0,0],byte_enable=0)
            assert tester.read(address,2)==[0x12ff,0xabff],hex(address)
        report['staging_boundaries']='pass'
        report['page_transfers']=[]
        for address in (0,0x800,0x7fe,0xfffffe,0x1fffffe,0x2fffffe,0x3fff800):
            words=[((i*71)^0x1234^(address>>1))&0xffff for i in range(1024)]
            if address: tester.write(address-2,[0xcafe])
            if address+2048<0x4000000: tester.write(address+2048,[0xbeef])
            before=tester.status()['run_id']
            started=time.monotonic()
            write_result=tester.write(address,words)
            assert write_result['run_id']==before+1 and write_result['operations']==1024
            assert tester.read(address,1024)==words,hex(address)
            assert tester.status()['run_id']==before+2
            elapsed=time.monotonic()-started
            tester.write(address,[0xffff]*1024,byte_enable=1)
            expected=[(v&0xff00)|255 for v in words]
            assert tester.read(address,1024)==expected
            tester.write(address,[0]*1024,byte_enable=0)
            assert tester.read(address,1024)==expected
            tester.write(address,[0x5a00]*1024,byte_enable=2)
            assert tester.read(address,1024)==[0x5aff]*1024
            if address: assert tester.read(address-2)==[0xcafe]
            if address+2048<0x4000000: assert tester.read(address+2048)==[0xbeef]
            report['page_transfers'].append({'address':address,'words':1024,'single_request':True,
                'masks_and_guards':'pass','host_write_read_seconds':elapsed,'fpga_write':write_result})
            print(f'PASS 2 KiB transfer at {address:#x}: one request per direction; masks and guards',flush=True)
        payload=bytes((i*37+11)&255 for i in range(2048))
        tester.write_page(0x2000,payload)
        assert tester.read_page(0x2000)==payload
        report['binary_page_api']='pass'
        print('PASS staging byte masks and row/bank/end boundaries',flush=True)
        tester.configure(Configuration(words=0x2000000,repeats=1000))
        run=tester.start()
        before=tester.status()
        assert before['busy']
        link.close()
        link,tester=connect()
        after=tester.status()
        assert after['run_id']==run and after['busy'] and after['owner'],after
        tester.stop()
        result=tester.wait(run_id=run)
        assert result['stopped'] and result['done'] and not result['failed'],result
        report['reconnect_stop']=result
        before=tester.status()['refresh_count']; time.sleep(.05)
        assert tester.status()['refresh_count']>before
        print('PASS reconnect, controlled stop, and refresh after stop',flush=True)
        if args.full:
            print('Running full 64 MiB address-pattern pass',flush=True)
            tester.configure(Configuration(words=0x2000000,pattern=2))
            result=tester.wait(timeout=120,run_id=tester.start())
            assert result['operations']==0x4000000 and not result['failed'] and not result['stopped'],result
            report['full_memory']=result
            print(f'PASS full 64 MiB: {result["bytes_per_second"]:.0f} logical bytes/s',flush=True)
        tester.release()
        report['final_status']=tester.status()
        assert not report['final_status']['owner']
        report['complete']=True
    except Exception as exc:
        report['error']=str(exc)
        raise
    finally:
        if link: link.close()
        Path(args.report).parent.mkdir(parents=True,exist_ok=True)
        Path(args.report).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')

if __name__=='__main__': main()
