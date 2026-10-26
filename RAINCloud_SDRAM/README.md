# RAINCloud SDRAM controller and tester

RAINCloud Digital | Jerry Campbell

Reusable 16-bit SDRAM controller, FPGA test engine and Python host API for the
Terasic DE10-Lite (MAX 10 **10M50DAF484C7G**). Controller **1.2.1**, firmware build
**26101404**, register API **1.1**. The supported hardware profile is **50 MHz,
CAS latency 3, sequential full-page SDRAM mode**, with a nominal +8 ns forwarded
clock. Logical requests contain 1–1,024 words; physical transfers split at row
boundaries and into at most 256-word segments to service refresh.

This is a curated snapshot of `SDRAM_Tester_Working` commit
`ac7c35debd8dd37b5bf392cfd43dfea5f934c3c2`, beside
[BE_8Bit_Computer](../BE_8Bit_Computer/) and [RAINCloud SAP](../RAINCloud_SAP/).
It is not integrated into either computer. [PUBLICATION.md](PUBLICATION.md)
records provenance, omissions, new checks and historical evidence boundaries.

## Source map

| Directory | Contents |
| --- | --- |
| `rtl/library/` | Byte-addressed controller with request/data/completion handshakes. |
| `rtl/tester/` | Pattern generation, checking, registers, ownership and snapshots. |
| `rtl/board/` | DE10-Lite controls, display, clock wrapper and board integration. |
| `host/` | Python client, CLI, mock transport and System Console bridge. |
| `tests/` | Portable controller/tester/board regressions and host tests. |
| `src/rtl/IS42S16320F.v` | RAINCloud behavioral memory model; not manufacturer qualification. |
| `src/ip/jtag_bridge.qsys` | JTAG system description; Intel IP generated locally. |
| `constraints/`, `quartus_project/`, `scripts/` | Timing/pin assignments and build/test runners. |
| `docs/` | Interfaces, timing assumptions and dated validation records. |

Production HDL is `rtl/`. Legacy controller/AXI experiments, old Questa projects,
vendor PDF copies, generated IP, runtimes, databases, waveforms and bitstreams are
omitted. Historical documents may mention omitted source-repository artifacts;
they are not active dependencies of this snapshot.

## Dependencies and portable tests

- Python **3.10+**, standard library only for the host API/tests; PowerShell runners.
- Icarus Verilog **13.0** (`iverilog`, `vvp`) for the recorded portable regression.
- Quartus Prime Lite **23.1std.1 Build 993**, MAX 10 support and Platform
  Designer/System Console for the recorded FPGA build and USB-Blaster transport.
  `create_jtag.tcl` requires Qsys **23.1** exactly; newer-tool compatibility is
  not claimed. Obtain vendor tools and licenses separately.

From this folder:

```powershell
./scripts/test.ps1 -Python python -Icarus 'C:/path/to/iverilog/bin'

# Host-only tests: mocks, no board required.
$env:PYTHONPATH = "$PWD/host"
python -m unittest discover -s tests -v
python -m sdram_client --transport mock status
```

The full runner executes five RTL runs (including CAS=2 model coverage), rejects
eight invalid parameter profiles and runs 26 host tests. CAS=2 has no hardware
qualification. The board bench uses behavioral clock/JTAG stubs. These tests do
not establish physical timing, signal integrity or board qualification.
`scripts/bootstrap_iverilog.py` is an optional explicit setup/download step;
testing does not install software automatically. Supply your Python executable's
full path if the WindowsApps alias does not work.

## Build

```powershell
./scripts/build.ps1 -Quartus 'C:/intelFPGA_lite/23.1std'
./scripts/test_jtag.ps1 -Quartus 'C:/intelFPGA_lite/23.1std' -Icarus 'C:/path/to/iverilog/bin'
```

The build regenerates `src/ip/jtag_bridge/`, compiles
`quartus_project/SDRAM_Test_Harness.qpf` and checks timing constraints. The QSF
pre-flow script applies reviewed adapter cleanup while retaining vendor notices.
Adapter tests require generated IP and its raw reference copies. Output is
`quartus_project/output_files/SDRAM_Test_Harness.sof`. Building does not program
a board. Generated Intel IP, license files and installers are not distributed.

## Host API

Page helpers transfer little-endian 16-bit words. The legacy 16-word staging
window remains compatible; API 1.1 adds page operations and per-word byte masks.
System Console communicates through the onboard USB-Blaster, without a soft CPU
or separate serial adapter. See [API.md](docs/API.md) and [BOARD.md](docs/BOARD.md).

```python
from sdram_client import Tester
from sdram_client.mock import MockTransport

transport = MockTransport()
ram = Tester(transport)
page = b"\x34\x12" * 1024
ram.write_page(0x10000, page)
assert ram.read_page(0x10000) == page
transport.close()
```

This example uses mock memory. The real `SystemConsoleTransport` writes physical
memory; use it only with a deliberately configured test setup.

## Validation and limits

October 14 records describe simulations, fitted timing and board measurements
for release builds including 26101404. They are **historical evidence**, not
measurements performed during this publication. [PUBLICATION.md](PUBLICATION.md)
lists new checks. There is no new synthesis, post-fit simulation, programming or
bench result here.

See [controller interface](docs/INTERFACE.md), [timing assumptions](docs/TIMING.md),
[testbench coverage](docs/TESTBENCH.md), [performance](docs/PERFORMANCE.md),
[warning cleanup](docs/WARNINGS.md) and the
[saved release manifest](docs/validation-warnings/source-manifest.json).
GPIO use, alternate board/timing profiles, overlapping buffering, CPU/cache/DMA
integration and arbitrary parameter combinations remain outside the recorded
qualification. Review and validate changes independently.

## License and attribution

[MIT license](LICENSE), copyright Jerry Campbell. File-level notices remain
intact; the memory model is credited to J. Campbell/RAINCloud. Terasic pin
assignments and Intel tool/IP dependencies are identified in source files.
Obtain generated Intel IP and vendor tools under their own terms; MIT does not
relicense them. This folder's license does not apply to SAP or the BE project.
