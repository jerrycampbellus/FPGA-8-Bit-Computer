# Quartus HDL warning cleanup — release 26101404

Controller **1.2.1 / API 1.1** makes intended widths and address decoding explicit
and removes unused bookkeeping from two generated JTAG adapters. The logical
request interface, CL3 mode, timing profile and page buffering are unchanged.

## The ten reported warnings

| Warning / source | Cause | Resolution |
|---|---|---|
| 10036, `jtag_bridge_master_timing_adt.sv`, `in_ready` | Local ready aliases feed only a simulation diagnostic | Diagnostic monitors `out_ready` directly; unused local aliases/assignments removed |
| 10036, `jtag_bridge_master_b2p_adapter.sv`, `out_channel` | No output-channel port exists in this generated configuration | Remove the unused local variable and its assignment |
| 10230, same adapter | Eight-bit input channel assigned to that unused one-bit variable | Assignment removed; the actual channel-zero valid filter remains |
| 10230, `tester_regs.sv`, request address | A 32-bit shifted word offset implicitly narrowed to 26 byte-address bits | Explicit `{offset_words[24:0],1'b0}` operand; whole-run range validation remains |
| 10230, `tester_regs.sv`, incrementing pattern | 32-bit arithmetic implicitly narrowed to the 16-bit data word | Explicit low-16-bit operands, preserving modulo-65536 arithmetic |
| 10762, `tester_regs.sv`, pattern selection | Case expression had 32 bits | Three-bit supported-ID selector with an explicit unsupported-ID fallback |
| 10762, `tester_regs.sv`, register reads | Case expression had 32 address bits | Eight-bit selector after checking the upper address bits; full-address array decoding retained |
| 10762, `tester_regs.sv`, register writes | Same oversized case expression | Same guarded selector; unknown/unaligned addresses cannot alias valid registers |
| 10230, `tester_regs.sv`, next request count | A 32-bit minimum implicitly narrowed to 11 bits | Compare full-width remaining/burst values, then explicitly select the bounded low 11 bits |
| 10230, `sdram_controller.sv`, segment count | Unsized `SEGMENT_MAX` widened the conditional expression | Declare the fixed limit as `localparam [10:0] SEGMENT_MAX=11'd256` |

These changes do not hide warning IDs. `scripts/build.ps1` rejects recurrence
of 10036/10230/10762 in these four reviewed source files, while retaining other
diagnostics for inspection. Source line numbers move as comments are updated;
the build check uses file names and warning codes.

## Regenerated Intel IP

The generated files under `src/ip/jtag_bridge/` remain ignored. The active QSF
runs [prepare_jtag.tcl](../scripts/prepare_jtag.tcl) through
`PRE_FLOW_SCRIPT_FILE` before a full compilation. This is the documented
[Quartus Standard pre-flow script mechanism](https://www.intel.com/programmable/technical-pdfs/683325.pdf).
It applies to the normal full GUI compilation and `quartus_sh --flow compile`;
it also follows fresh generation in `scripts/build.ps1 -Regenerate`.

The script checks known generator parameters and exact unique fragments before
editing. Both transformations are validated before either file is written.
It is idempotent, preserves vendor notices, and makes no edits to installed
Intel templates. Unexpected fragment/parameter changes fail with a diagnostic
instead of silently applying the cleanup to a different adapter configuration.
Raw generated copies are retained in `build/jtag-raw/` for comparison.

The output ports, valid/ready behavior, packet flags and channel-zero filter are
unchanged. The timing adapter's existing simulation-only backpressure message
remains, triggered directly by the downstream ready port.

For a standalone tool invocation that bypasses the full flow, prepare first:

```powershell
& C:/intelFPGA_lite/23.1std/quartus/bin64/quartus_sh.exe -t scripts/prepare_jtag.tcl
```

## Regression and reproduction

```powershell
./scripts/test.ps1 -Python python
./scripts/build.ps1 -Regenerate
./scripts/test_jtag.ps1
```

Pass the full path to your Python executable if the WindowsApps alias
does not launch. The portable regression adds high-address/unaligned register
rejection, unsupported pattern IDs and a 16-bit overflow example to the existing
controller/tester/page coverage.

The optional generated-IP check uses Quartus Tcl plus Icarus. It checks cleanup
idempotence and rejection of generator drift, then compares prepared adapter
ports against renamed raw generated modules for **1,048,576** combinations:
all 256 channel values, 256 data values and 16 valid/ready/packet-flag combinations.
Clock/reset inputs also vary. These are combinational adapter checks, not a
simulation of the complete USB-Blaster/JTAG subsystem. Real JTAG transfers are
covered separately by the connected-board acceptance run.

Logs are in `build/jtag-check/`; the completed release measurements and remaining
Quartus diagnostics are recorded in [VALIDATION.md](VALIDATION.md).
