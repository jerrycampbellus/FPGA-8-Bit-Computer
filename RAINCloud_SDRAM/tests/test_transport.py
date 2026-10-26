import io
import queue
import threading
import types
import unittest
from sdram_client.transport import SystemConsoleTransport, TransportError

class TransportTests(unittest.TestCase):
    def link(self, *lines):
        link=SystemConsoleTransport.__new__(SystemConsoleTransport)
        link._id=0; link._lock=threading.Lock(); link.timeout=.01
        link._process=types.SimpleNamespace(stdin=io.StringIO())
        link._lines=queue.Queue()
        for line in lines: link._lines.put(line)
        return link

    def test_repl_prefix_and_request_id(self):
        link=self.link('unrelated startup banner','% @0 OK ready','% @1 OK 0x12345678 0xffffffff')
        self.assertEqual(link.read32(0,2),[0x12345678,0xffffffff])
        self.assertEqual(link._process.stdin.getvalue(),'sdram_rpc 1 R 0 2\n')

    def test_timeout_does_not_replay_write(self):
        link=self.link()
        with self.assertRaises(TransportError): link.write32(0x14,[0x101])
        self.assertEqual(link._process.stdin.getvalue().count(' W '),1)

    def test_error_and_eof(self):
        for response in ['% @1 ERR connection lost',None]:
            with self.assertRaises(TransportError): self.link(response).read32(0)

    def test_malformed_reply(self):
        for response in ['@1 OK rubbish','@1 OK 0x100000000','@1 OK 1 2']:
            with self.assertRaises(TransportError): self.link(response).read32(0)

    def test_page_transport_chunking(self):
        words=list(range(1024))
        replies=[f'@{i+1} OK '+ ' '.join(map(str,words[i*128:(i+1)*128])) for i in range(8)]
        link=self.link(*replies)
        self.assertEqual(link.read32(0x1000,1024),words)
        self.assertEqual(len(link._process.stdin.getvalue().splitlines()),8)
        self.assertIn('R 7680 128',link._process.stdin.getvalue())
        link=self.link(*[f'@{i+1} OK written' for i in range(8)])
        link.write32(0x1000,words)
        self.assertEqual(len(link._process.stdin.getvalue().splitlines()),8)
        self.assertIn('W 7680 128 896',link._process.stdin.getvalue())

    def test_partial_page_write_failure_is_not_replayed(self):
        link=self.link('@1 OK written','@2 ERR connection lost')
        with self.assertRaises(TransportError): link.write32(0x1000,list(range(1024)))
        self.assertEqual(len(link._process.stdin.getvalue().splitlines()),2)

    def test_numeric_bounds(self):
        link=self.link()
        for address,count in [(1,1),(512,1),(0,129),(-4,1),(0,0),(0x1000,1025),(0x1ffc,2),(0xffc,2),(0x2000,1)]:
            with self.assertRaises(ValueError): link.read32(address,count)
        with self.assertRaises(ValueError): link.write32(0,[-1])
        self.assertEqual(link._process.stdin.getvalue(),'')

if __name__=='__main__': unittest.main()
