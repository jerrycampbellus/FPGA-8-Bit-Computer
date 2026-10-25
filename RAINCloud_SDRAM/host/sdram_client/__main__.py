import argparse
from dataclasses import asdict
import json
import sys
from .client import Tester, Configuration
from .transport import SystemConsoleTransport
from .mock import MockTransport

def number(text): return int(text,0)

def main():
    parser = argparse.ArgumentParser(description='DE10-Lite SDRAM tester (JTAG USB-Blaster)')
    parser.add_argument('--transport',choices=['jtag','mock'],default='jtag')
    parser.add_argument('--system-console',default='system-console')
    parser.add_argument('--service-index',type=int)
    parser.add_argument('--timeout',type=float,default=30)
    parser.add_argument('--report',help='Save JSON report')
    sub = parser.add_subparsers(dest='command',required=True)
    for name in ['status','start','stop','results','release']:
        sub.add_parser(name)
    for name in ['configure','run']:
        p=sub.add_parser(name)
        for field,default in asdict(Configuration()).items():
            p.add_argument('--'+field,type=number,default=default)
    p=sub.add_parser('read'); p.add_argument('address',type=number); p.add_argument('words',type=number,nargs='?',default=1)
    p=sub.add_parser('write'); p.add_argument('address',type=number); p.add_argument('data',type=number,nargs='+'); p.add_argument('--byte-enable',type=number,default=3)
    p=sub.add_parser('read-page',help='Read one aligned 2 KiB page into a binary file')
    p.add_argument('address',type=number); p.add_argument('--output',required=True)
    p=sub.add_parser('write-page',help='Write one aligned 2 KiB page from a binary file')
    p.add_argument('address',type=number); p.add_argument('input')
    args=parser.parse_args()
    transport=None
    try:
        transport=MockTransport() if args.transport=='mock' else SystemConsoleTransport(args.system_console,service_index=args.service_index)
        tester=Tester(transport)
        if args.command in ['configure','run']:
            cfg=Configuration(**{k:getattr(args,k) for k in asdict(Configuration())})
            tester.configure(cfg)
            result=asdict(cfg) if args.command=='configure' else tester.wait(timeout=args.timeout,run_id=tester.start())
        elif args.command=='start': result={'run_id':tester.start()}
        elif args.command=='stop': tester.stop(); result=tester.wait(timeout=args.timeout)
        elif args.command=='read': result={'address':args.address,'data':tester.read(args.address,args.words)}
        elif args.command=='write': result=tester.write(args.address,args.data,byte_enable=args.byte_enable)
        elif args.command=='read-page':
            from pathlib import Path
            data=tester.read_page(args.address)
            Path(args.output).write_bytes(data)
            result={'address':args.address,'bytes':len(data),'output':str(Path(args.output).resolve())}
        elif args.command=='write-page':
            from pathlib import Path
            result=tester.write_page(args.address,Path(args.input).read_bytes())
        elif args.command=='release': tester.release(); result=tester.status()
        else: result=getattr(tester,args.command)()
        result['transport']=args.transport
        output=json.dumps(result,indent=2)
        print(output)
        if args.report:
            from pathlib import Path
            Path(args.report).write_text(output+'\n',encoding='utf-8')
        return 1 if result.get('failed') else 0
    except (RuntimeError,ValueError,TimeoutError,OSError) as exc:
        print(json.dumps({'error':str(exc)}),file=sys.stderr)
        return 2
    finally:
        if transport: transport.close()

if __name__=='__main__': sys.exit(main())
