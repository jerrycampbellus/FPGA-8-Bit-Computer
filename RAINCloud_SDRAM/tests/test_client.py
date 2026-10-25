import unittest
from sdram_client import Tester, Configuration
from sdram_client.mock import MockTransport

class ClientTests(unittest.TestCase):
    def setUp(self):
        self.link=MockTransport()
        self.tester=Tester(self.link)

    def test_patterns_and_counts(self):
        for pattern in range(7):
            self.tester.configure(Configuration(start=0x7f0,words=33,repeats=2,pattern=pattern,flags=3))
            run=self.tester.start()
            r=self.tester.wait(run_id=run)
            self.assertTrue(r['done'])
            self.assertFalse(r['failed'])
            self.assertEqual(r['operations'],66*(7 if pattern==6 else 2))
            self.assertEqual(r['bytes'],r['operations']*2)

    def test_reconnect_keeps_run_and_ownership(self):
        self.tester.configure(Configuration())
        run=self.tester.start()
        self.link.close()
        other=Tester(self.link)
        self.assertTrue(other.status()['owner'])
        self.assertEqual(other.wait(run_id=run)['run_id'],run)

    def test_stop_and_release(self):
        self.tester.configure(Configuration())
        self.tester.start()
        self.tester.stop()
        self.assertTrue(self.tester.results()['stopped'])
        self.tester.release()
        self.assertFalse(self.tester.status()['owner'])

    def test_staging_and_byte_masks(self):
        self.tester.write(0x7fe,[0x1234,0xabcd])
        self.tester.write(0x7fe,[0xffff,0xffff],byte_enable=1)
        self.assertEqual(self.tester.read(0x7fe,2),[0x12ff,0xabff])
        self.tester.write(0x7fe,[0,0],byte_enable=0)
        self.assertEqual(self.tester.read(0x7fe,2),[0x12ff,0xabff])

    def test_page_roundtrip_and_single_request(self):
        payload=bytes((i*37+11)&255 for i in range(2048))
        before=self.link.read32(0x50)[0]
        self.tester.write_page(0x3fff800,payload)
        self.assertEqual(self.link.read32(0x50)[0],before+1)
        self.assertEqual(self.tester.read_page(0x3fff800),payload)
        self.assertEqual(self.link.read32(0x50)[0],before+2)
        self.assertEqual(self.link.read32(0x100,16),self.link.read32(0x1000,16))

    def test_mixed_application_requests_and_per_word_masks(self):
        # Byte store, cache line and page DMA use the same controller profile.
        for count in (1,16,1024,3):
            with self.subTest(words=count):
                address=0x7fe
                self.tester.write(address,[0x1234]*count)
                before=self.link.read32(0x50)[0]
                masks=[i%4 for i in range(count)]
                self.tester.write(address,[0xabcd]*count,byte_enables=masks)
                self.assertEqual(self.link.read32(0x50)[0],before+1)
                self.assertEqual(self.tester.read(address,count),
                                 [[0x1234,0x12cd,0xab34,0xabcd][m] for m in masks])

    def test_invalid_per_word_masks_before_mutations(self):
        for masks in ([],[3],[3,3,3],[3,4],[3,-1],[True,3],[3,1.5]):
            with self.assertRaises(ValueError):
                self.tester.write(0,[1,2],byte_enables=masks)
        self.assertFalse(self.tester.status()['owner'])
        self.assertEqual(self.link.read32(0x50)[0],0)

    def test_page_boundaries_and_masks(self):
        words=[(i*71)^0x1234 for i in range(1024)]
        words=[v&0xffff for v in words]
        self.tester.write(0xfffffe,words)
        self.tester.write(0xfffffe,[0xffff]*1024,byte_enable=1)
        self.assertEqual(self.tester.read(0xfffffe,1024),[(v&0xff00)|255 for v in words])
        self.tester.write(0xfffffe,[0]*1024,byte_enable=0)
        self.assertEqual(self.tester.read(0xfffffe,1024),[(v&0xff00)|255 for v in words])

    def test_page_rejection_before_mutations(self):
        for address in (-2048,2,0x4000000):
            with self.assertRaises(ValueError): self.tester.read_page(address)
        for data in (b'',bytes(2047),bytes(2049),[0]*2048):
            with self.assertRaises(ValueError): self.tester.write_page(0,data)
        with self.assertRaises(ValueError): self.tester.read(0,1025)
        with self.assertRaises(ValueError): self.tester.read(0x3fff802,1024)
        self.assertFalse(self.tester.status()['owner'])
        self.assertEqual(self.link.read32(0x50)[0],0)

    def test_legacy_firmware_capability_limit(self):
        self.link.regs[4]=0x10000
        self.link.regs[12]=0x7f
        legacy=Tester(self.link)
        self.assertEqual(legacy.max_words,16)
        legacy.write(0,[0x1234])
        self.assertEqual(legacy.read(0),[0x1234])
        legacy.release()
        with self.assertRaises(ValueError): legacy.read_page(0)
        with self.assertRaises(ValueError): legacy.configure(Configuration(burst=1024))
        self.assertFalse(legacy.status()['owner'])

    def test_invalid_configuration_before_writes(self):
        for cfg in [Configuration(start=1),Configuration(words=0),Configuration(start=0x3fffffe,words=2),Configuration(pattern=7),Configuration(burst=1025),Configuration(repeats=0),Configuration(flags=4)]:
            with self.assertRaises(ValueError): self.tester.configure(cfg)
        self.assertFalse(self.tester.status()['owner'])

    def test_busy_rejects_writes(self):
        self.tester.configure(Configuration())
        self.tester.start()
        with self.assertRaises(RuntimeError): self.tester.write(0,[1])

    def test_version_mismatch(self):
        self.link.regs[4]=0x20000
        with self.assertRaises(RuntimeError): Tester(self.link)

    def test_duplicate_nonce_is_idempotent(self):
        self.tester.configure(Configuration())
        self.tester.start()
        command=self.link.read32(0x14)[0]
        self.link.write32(0x14,[command])
        self.assertEqual(self.link.read32(0x50)[0],1)

    def test_snapshot_is_immutable(self):
        self.tester.configure(Configuration(words=7))
        self.tester.wait(run_id=self.tester.start())
        snapshot=self.link.read32(0x80,16)
        self.tester.start()
        self.assertEqual(self.link.read32(0x80,16),snapshot)

    def test_raw_invalid_command_ack(self):
        with self.assertRaises(RuntimeError): self.tester.command(255)
        self.assertEqual(self.link.read32(0x18)[0],4)

    def test_64_bit_metrics(self):
        self.tester.configure(Configuration(words=0x2000000,repeats=128))
        result=self.tester.wait(run_id=self.tester.start())
        self.assertEqual(result['operations'],1<<33)
        self.assertEqual(result['bytes'],1<<34)
        self.assertEqual(result['cycles'],20<<33)

if __name__=='__main__': unittest.main()
