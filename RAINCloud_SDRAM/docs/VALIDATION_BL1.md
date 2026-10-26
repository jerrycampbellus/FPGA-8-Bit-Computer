# Validation record — 2026-10-14

The new library and tester passed simulation, static timing and connected
DE10-Lite acceptance. The full 64 MiB address-pattern write/read test completed
with zero errors. The user also confirmed that the physical controls and displays
work. This record covers firmware build ID `26101401`, API `1.0`, at 50 MHz.

## Source and tools

Work was performed in `SDRAM_Tester_Working`, branch `work/sdram-tester`, based on
commit `ed6d0eb7dd0a833e767ce2f699c9b9ae83219b81`. The implementation and this
evidence are local, uncommitted changes. The six pre-existing Questa MPF relocation
edits and ignored waveform scripts were preserved. The original repositories
were not changed, and nothing was pushed.

- Quartus Prime Lite 23.1std.1, Build 993, 2024-05-14.
- FPGA: MAX 10 `10M50DAF484C7G`; onboard USB-Blaster connection.
- Icarus Verilog 13.0 for the three self-checking RTL regressions.
- Python standard-library unittest for the host API and transport tests.
- [Source and bitstream hashes](validation/source-manifest.json).

Build, test, programming and Python commands are in the [README](../README.md).
The active design is under `rtl/`; preserved legacy HDL is not a second supported
controller.

## Baseline and timing

The original design compiled, but its worst setup slack was **−2.894 ns**. Its
constraints did not establish SDRAM I/O timing. The original Questa source
compilation worked; loading the simulation failed because the installed
`intelqsimstarter` license was expired. An Icarus attempt could not compile the
legacy Intel simulation primitives. No legacy simulation pass is claimed.

The new design passed all reported timing corners:

| Check | Result |
|---|---:|
| Worst setup slack | +1.524 ns |
| Worst hold slack | +0.149 ns |
| Unconstrained setup/hold paths and ports | 0 |
| Logic elements | 7,672 / 49,760 (15%) |
| Registers | 3,792 |
| Embedded memory bits | 1,024 |
| PLLs | 1 |

Evidence: [baseline timing](validation/baseline-timing.txt),
[baseline resources](validation/baseline-fit.txt),
[final timing](validation/final-timing.txt),
[constraint coverage](validation/final-unconstrained.txt), and
[final resources](validation/final-fit.txt).
The [timing profile](TIMING.md) explains the forwarded clock and I/O assumptions.

## Regression results

All **three RTL suites and 16 Python tests passed**. The
[saved regression output](validation/regression-summary.txt) records each result.

- Controller: 504 comparisons, logical lengths 1–16, all byte enables,
  row/bank/end boundaries, invalid requests, stalled channels and refresh deadlines.
- Tester: all seven patterns, repeats, stalls, retention gaps, ownership,
  controlled stop, 64-bit counters, coherent snapshots, injected failures,
  bounded error log, direct staging and a standalone 1,024-word run.
- Board: power-on reset, debounced keys, local start/pass/stop, progress LEDs,
  page selection and parameter editing using simulation substitutes for PLL/JTAG.
- Host: configuration validation, byte masks, counters, ownership/reconnection,
  nonce deduplication, snapshots, version checks, response parsing, timeouts,
  EOF/error handling and numeric bounds.

The controller and tester regressions use the existing ISSI SDRAM model. They
reported no model timing errors. The host mock tests are functional API tests;
the hardware evidence below used the actual JTAG transport.

## Connected-board acceptance

The [programming log](validation/programming.txt) confirms successful volatile
SOF programming. Boot flash was not programmed. The
[automated hardware report](validation/hardware-results.json) records:

- Patterns 0–6 over 257 words, two repeats, read/write stalls and retention gaps:
  zero errors in every case.
- Direct staging reads/writes, byte masks and row/bank/end boundaries: passed.
- Disconnect/reconnect during a running test: run ID and host ownership retained.
- Controlled stop and refresh continuing after stop: passed.
- Full 64 MiB address-pattern write/read: passed with zero errors.

| Full-memory measurement | Result |
|---|---:|
| Run ID | 39 |
| Words tested | 33,554,432 |
| Read + write word operations | 67,108,864 |
| Logical bytes transferred | 134,217,728 |
| FPGA clock cycles | 932,051,479 |
| FPGA-measured duration | 18.64102958 s |
| Combined read + write throughput | 7,200,124 bytes/s |
| Comparison errors | 0 |

The automated script released host ownership afterward. For the physical check,
the user was asked to start/stop with KEY1, observe LED0 and changing value digits,
and change pages with KEY0. The user replied: **“Controls and displays work.”**
This is the evidence for the physical interaction; JTAG cannot observe the user's
button presses or the visible LEDs directly.

A subsequent [JTAG snapshot](validation/local-controls-results.json) showed run
49 complete, local ownership, all 33,554,432 words tested and zero errors, in
18.64102982 s. That snapshot records a completed run, not a stopped run. The
separate automated stop test above provides the recorded controlled-stop evidence.
At the final readback the board was initialized and idle with local ownership.

## Qualification limits and future work

This is the first supported correctness baseline: physical BL1 with buffered
logical transfers up to 16 words, CL3 and a 50 MHz core. The measured throughput
includes controller overhead and refresh; it is not peak SDRAM bandwidth.
Physical BL4/BL8 optimization remains a future change behind the same interface.

Board testing was functional testing at ambient conditions. Static timing uses
the specified FPGA corners and a 0.5 ns board trace-skew allowance; that allowance
is an engineering assumption, not measured PCB flight times. Temperature/voltage
margin testing and the A2 refresh profile above 85 °C were not performed.

CPU/cache and DMA/tile-buffer clients are documented extension points. UART
framing is specified for a future transport; UART hardware and those application
clients are outside this implementation.
