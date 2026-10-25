import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from sdram_client.__main__ import main
from sdram_client.mock import MockTransport


class PageCliTests(unittest.TestCase):
    def invoke(self, link, *args):
        output, errors = io.StringIO(), io.StringIO()
        with patch('sys.argv', ['sdram_client', '--transport', 'mock', *args]), \
             patch('sdram_client.__main__.MockTransport', return_value=link), \
             contextlib.redirect_stdout(output), contextlib.redirect_stderr(errors):
            code = main()
        return code, output.getvalue(), errors.getvalue()

    def test_binary_page_files_roundtrip(self):
        link = MockTransport()
        payload = bytes((i*19+7)&255 for i in range(2048))
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory)/'source.bin', Path(directory)/'result.bin'
            source.write_bytes(payload)
            code, output, _ = self.invoke(link, 'write-page', '0x800', str(source))
            self.assertEqual(code, 0)
            self.assertEqual(json.loads(output)['operations'], 1024)
            code, output, _ = self.invoke(link, 'read-page', '0x800', '--output', str(target))
            self.assertEqual(code, 0)
            self.assertEqual(json.loads(output)['bytes'], 2048)
            self.assertEqual(target.read_bytes(), payload)
            self.assertEqual(link.regs[0x50], 2)

    def test_invalid_file_leaves_memory_untouched(self):
        link = MockTransport()
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)/'short.bin'
            source.write_bytes(b'short')
            code, _, errors = self.invoke(link, 'write-page', '0', str(source))
            self.assertEqual(code, 2)
            self.assertIn('2048', errors)
            self.assertEqual(link.regs[0x50], 0)
            self.assertEqual(link.memory, {})


if __name__ == '__main__':
    unittest.main()
