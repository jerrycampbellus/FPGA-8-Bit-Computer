# Configuration and application-interface validation — 2026-10-14

**RAINCloud controller 1.2, firmware 26101403, register API 1.1** is programmed
on the DE10-Lite. The released profile remains 50 MHz / CL3 / sequential full-page
bursts / nominal +8 ns forwarded clock. Boot flash was not changed.

The previous releases remain documented in [VALIDATION_PAGE.md](VALIDATION_PAGE.md)
(build 26101402) and [VALIDATION_BL1.md](VALIDATION_BL1.md) (build 26101401).

## Changes

- MODE is assembled from named physical-format fields. One `CAS` parameter
  configures both the chip's latency field and the controller's capture pipeline.
  `TMRD` names the mode-recovery setting. Invalid parameter ranges fail elaboration.
- Sequential full-page bursts and burst writes remain fixed scheduler requirements.
  Applications choose address, actual count (1..1024) and per-word byte enables
  through the request interface, with no runtime MODE command.
- Python `write(..., byte_enables=[...])` supports per-word masks, validated before
  ownership or staging changes. Uniform `byte_enable=3` and page helpers retain
  their existing behavior. The existing staging register format already supports
  these masks, so the register API remains 1.1.
- Added a model-based cycle profiler, a hardware request-size benchmark, and the
  [performance investigation](PERFORMANCE.md). Open-row reuse and overlapping
  buffering were investigated, not added to the production scheduler.

## Simulation and host tests

[Regression output](validation-config/regression-summary.txt) records **five RTL
runs, eight rejected invalid profiles, and 26 passing Python tests**:

- Controller at CAS=3 and CAS=2: 17,191 comparisons per run, including masks,
  lengths 1..1024, row/bank/end boundaries, adjacent guards, continuous pages,
  input/output/completion stalls and the 380-cycle refresh deadline. Pin monitoring
  checks MODE=0x037/0x027 respectively, one load across mixed request sizes, and
  initialization recovery.
- Tester and board regressions: all seven patterns, page requests and tails,
  staging/legacy alias, snapshots, ownership, controlled stop and local controls.
- Performance profiler: 60 cases, 98,160 comparisons, separate client/physical
  data counts, command counts, row-reuse candidates and refresh checks.
- Host tests: per-word masks and invalid-mask rejection before mutation, plus all
  previous word/page/CLI, capability fallback and transport-failure tests.

Icarus rejects CAS=1/4, MAX_WORDS=0/1025, TMRD=1, TRP=0 and refresh intervals
280/65536. A separate [Quartus elaboration check](validation-config/quartus-invalid-cas.txt)
confirms CAS=1 is rejected with `SDRAM_CONFIG_ERROR__CAS_must_be_2_or_3`.
These guards catch structural configuration errors; arbitrary timing values still
require datasheet and board review. CL2 has model coverage only and was not
programmed onto the board. The existing Questa simulation license is expired;
Icarus 13.0 supplied the functional simulation results.

## Build and timing

Quartus Prime Lite 23.1std.1 Build 993 compiled the active
`quartus_project/SDRAM_Test_Harness.qpf` for MAX 10 10M50DAF484C7G.

| Measurement | Result |
|---|---:|
| Worst setup slack | +1.524 ns |
| Worst hold slack | +0.143 ns |
| Unconstrained clocks, setup/hold ports and paths | 0 |
| Logic elements | 7,218 / 49,760 |
| Registers | 3,490 |
| Embedded memory bits | 72,192 / 1,677,312 |
| PLLs | 1 |

Evidence: [timing](validation-config/final-timing.txt),
[constraint coverage](validation-config/final-unconstrained.txt),
[resources](validation-config/final-fit.txt),
[programming](validation-config/programming.txt), and
[exact source/bitstream hashes](validation-config/source-manifest.json).
The 0.5 ns trace-skew assumption and qualification boundaries remain in
[TIMING.md](TIMING.md). Default buffers and physical command scheduling are unchanged.

The subsequent code-comment/testbench documentation update adds RAINCloud headers,
task/monitor descriptions and [TESTBENCH.md](TESTBENCH.md). All eight annotated
HDL files and the PowerShell runner retain their accepted executable token
sequences. Positive/negative elaboration and 26 host tests passed again; functional
simulation was not repeated for comments alone. The original build/test source
hashes remain in the manifest, with annotated hashes recorded separately under
`post_validation_documentation`. The [documentation check](validation-config/documentation-check.json)
confirms the SOF hash is unchanged; no rebuild or board programming was performed.

SOF SHA-256:
`f9882b262451ea8291a26d3bc196f4333984407eee4a3102cd855e76e7f914eb`.
The accepted SOF is also saved at `build/accepted-config/SDRAM_Test_Harness.sof`;
the prior page SOF remains at `build/accepted-page/SDRAM_Test_Harness.sof`.

## Connected-board acceptance

The [hardware acceptance report](validation-config/hardware-results.json) confirms
build 26101403, all seven patterns with stalls and retention gaps, full-page
transfers at row/bank/end boundaries, byte masks, adjacent guards, binary page
round trip, reconnect, controlled stop and continuing refresh.

| Full-memory address-pattern pass | Result |
|---|---:|
| Run ID | 121 |
| Words tested | 33,554,432 |
| Read + write word operations | 67,108,864 |
| Logical bytes transferred | 134,217,728 |
| FPGA cycles | 138,870,787 |
| Duration | 2.77741574 s |
| Combined read + write throughput | 48,324,680.410 bytes/s |
| Comparison errors | 0 |

This confirms the configuration refactor preserves approximately 48.325 MB/s of
FPGA tester throughput. It is not a USB/JTAG transfer-rate measurement.
The [hardware benchmark](validation-config/hardware-benchmark.json) separately
repeats sizes 1..1024 at two alignments and tests 1-, 16-, 1024- and 3-word
application requests with per-word byte masks and one FPGA write request per call.

The final board status is saved in [final-status.json](validation-config/final-status.json).
Physical buttons/displays were user-confirmed on the earlier release; the board
simulation passed here, but no new manual observation is claimed. These results
are ambient functional checks and timing analysis, not temperature/voltage margin
qualification. Runtime MODE changes and a CL2 hardware profile remain future work.

Changes remain local and uncommitted on `work/sdram-tester`, based on
`ed6d0eb7dd0a833e767ce2f699c9b9ae83219b81`. The six pre-existing MPF relocation
edits and ignored waveform files are preserved. Nothing was pushed.
