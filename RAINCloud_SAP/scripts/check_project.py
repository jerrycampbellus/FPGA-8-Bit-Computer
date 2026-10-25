# RAINCloud Digital | RAINCloud_SAP
# Original SAP design and codebase: J. Campbell.
#
"""Portable structural checks; not a replacement for RTL simulation or STA."""
from pathlib import Path
import hashlib, json, re

root=Path(__file__).resolve().parents[1]

def require_file(relative):
    # Detect Windows-only case mismatches before a Linux/macOS checkout fails.
    path=root
    for part in Path(relative).parts:
        assert part in {child.name for child in path.iterdir()}, f'Missing or mismatched path case: {relative}'
        path=path/part
    assert path.is_file(), f'Missing file: {relative}'
    return path

qsf=(root/'RAINCloud_SAP.qsf').read_text()
files=re.findall(r'-name VERILOG_FILE (.+)',qsf)
assert len(files)==len(set(files)), 'Duplicate sources'
assert set(files)==set((root/'sim/sources.f').read_text().splitlines()), 'Build/sim source mismatch'
modules={}
for name in files:
    path=require_file(name)
    text=path.read_text()
    assert not re.search(r'[A-Za-z]:[\\/]',text), f'Absolute path in {name}'
    for module in re.findall(r'\bmodule\s+(\w+)',text):
        assert module not in modules, f'Duplicate module {module}'
        modules[module]=name
assert 'RAINCloud_SAP' in modules
pins=(root/'constraints/de10_lite_pins.qsf').read_text()
assignments=re.findall(r'set_location_assignment (\w+) -to (\S+)',pins)
assert len(assignments)==71, f'Expected 71 board pins; got {len(assignments)}'
assert len({pin for pin,signal in assignments})==71, 'Duplicate physical pin'
assert len({signal for pin,signal in assignments})==71, 'Duplicate port pin assignment'
expected={'MAX10_CLK1_50'}|{f'KEY[{i}]' for i in range(2)}
expected|={f'{bus}[{i}]' for bus in ['SW','LEDR'] for i in range(10)}
expected|={f'HEX{h}[{i}]' for h in range(6) for i in range(8)}
assert {signal for pin,signal in assignments}==expected, 'Board interface mismatch'
io_signals=set(re.findall(r'set_instance_assignment -name IO_STANDARD .+ -to (\S+)',pins))
assert io_signals==expected, 'Missing/extra IO standard'
image=(root/'programs/ram_init.hex').read_text().split()
assert len(image)==16 and all(0<=int(x,16)<=255 for x in image)
manifest=json.loads((root/'reference/SOURCE_MANIFEST.json').read_text())
for entry in manifest:
    actual=hashlib.sha256(require_file(entry['reference']).read_bytes()).hexdigest()
    assert actual==entry['sha256'], f'Original baseline changed: {entry["reference"]}'
print(f'PASS structure: {len(modules)} modules, {len(assignments)} pins, 16 bytes, {len(manifest)} source hashes')
