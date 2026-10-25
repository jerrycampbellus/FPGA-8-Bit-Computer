# Quartus warning-cleanup validation — 2026-10-14

**RAINCloud controller 1.2.1 / firmware 26101404 / register API 1.1** is programmed
on the DE10-Lite. The ten reported HDL warnings are absent after fresh Qsys
regeneration and a complete Quartus build. The board passed page transfers and
full 64 MiB write/read acceptance and is idle under local ownership.

The earlier [configuration release](VALIDATION_CONFIG.md),
[page release](VALIDATION_PAGE.md) and [BL1 release](VALIDATION_BL1.md) retain their
original evidence. Nothing was committed or pushed.

## Warning resolution

[WARNINGS.md](WARNINGS.md) describes each source change. Our RTL now explicitly
sizes request addresses, incrementing data, logical counts and physical segment
counts. Bounded case selectors preserve rejection of high/unaligned addresses
and unsupported pattern IDs. A QSF pre-flow hook removes unused bookkeeping from
two generated adapters while preserving their ports, channel-zero filter and
simulation diagnostic. Fresh IP generation is supported; installed Intel templates
are untouched and no message IDs are suppressed.

The [warning audit](validation-warnings/warning-audit.json) records **10 targeted
warnings before, zero after**. The build script rejects their recurrence in the
four reviewed files. Total diagnostic lines fell from 35 to 25. The remaining
messages are retained for inspection:

- Three inferred staging-RAM read-during-write diagnostics. The API requires
  staged-result reads after completion and does not promise a coherent live RAM view.
- Trimmed DSP/connectivity diagnostics, intentionally constant output pins and
  unused SW7/SW8 inputs.
- LogicLock subscription notice, incomplete I/O-assignment advisory, non-dedicated
  PLL-to-SDRAM-clock routing warning, and MAX 10 interface-voltage requirements.

These remaining board/IP diagnostics are not declared resolved by this cleanup.
Pin assignments, the forwarded-clock profile and I/O constraints were not changed;
see [TIMING.md](TIMING.md) for their assumptions and qualification boundaries.

## Regression

The [portable regression](validation-warnings/regression-summary.txt) passed all
five RTL runs, eight expected invalid-profile elaborations and **26 Python tests**.
Controller CL3 and CL2 each completed 17,191 comparisons; the performance bench
completed 98,160 comparisons over 60 cases. Tester and board suites also passed.
New tester checks cover unknown/high/unaligned register addresses, unsupported
pattern IDs and 16-bit incrementing-pattern wrap. CL2 remains model-tested only;
the programmed release uses CL3.

The [generated-adapter checks](validation-warnings/adapter-tests.txt) passed:
cleanup idempotence, rejection of changed generator fragments/parameters, and
**1,048,576 raw/prepared port comparisons** across all binary channel/data and
valid/ready/packet-flag combinations. Clock/reset also varied. These checks use
renamed original generated modules rather than a second hand-written adapter.
They supplement real JTAG acceptance; they do not simulate the entire JTAG core.
See [TESTBENCH.md](TESTBENCH.md) for commands, scope and debugging.

## Regenerated build and static timing

`./scripts/build.ps1 -Regenerate` generated the IP and compiled the active
`quartus_project/SDRAM_Test_Harness.qpf` with Quartus Prime Lite 23.1std.1 Build 993
for MAX 10 10M50DAF484C7G. The pre-flow hook ran successfully. All timing corners
passed, with zero unconstrained clocks/setup/hold ports and paths.

| Measurement | Result |
|---|---:|
| Worst setup slack | +1.524 ns |
| Worst hold slack | +0.130 ns |
| Logic elements | 7,111 / 49,760 |
| Registers | 3,490 |
| Embedded memory bits | 72,192 / 1,677,312 |
| PLLs | 1 |

Evidence: [IP generation](validation-warnings/ip-generation.txt),
[timing](validation-warnings/final-timing.txt),
[constraint coverage](validation-warnings/final-unconstrained.txt),
[resources](validation-warnings/final-fit.txt),
[programming](validation-warnings/programming.txt), and
[source/generated-IP/bitstream hashes](validation-warnings/source-manifest.json).

SOF SHA-256:
`f57920cfb432964f516e826a2da182b0ca75b5eb0885b231f9faa5b445f76176`.
A copy is saved at `build/accepted-warnings/SDRAM_Test_Harness.sof`; earlier
accepted SOFs remain in their existing build subdirectories. Programming changed
volatile FPGA configuration only, not boot flash.

## Connected-board acceptance

The [hardware report](validation-warnings/hardware-results.json) identifies build
26101404 and confirms all seven patterns with stalls/retention gaps, full-page
transfers at row/bank/end boundaries, byte masks, adjacent guards, binary page
round trip, reconnect, controlled stop and continuing refresh.

| Full 64 MiB address-pattern pass | Result |
|---|---:|
| Run ID | 121 |
| Words tested | 33,554,432 |
| Read + write word operations | 67,108,864 |
| Logical bytes transferred | 134,217,728 |
| FPGA clock cycles | 138,870,787 |
| Duration | 2.77741574 s |
| Combined read + write throughput | 48,324,680.410 bytes/s |
| Comparison errors | 0 |

The throughput is FPGA tester traffic, not USB/JTAG speed. Buffering, refresh,
MODE and the 1..1024-word request contract remain unchanged. The [final status](validation-warnings/final-status.json)
records initialized, idle, no errors and local ownership. No new physical-button
observation or temperature/voltage margin qualification is claimed.

Changes remain local on `work/sdram-tester`, based on
`ed6d0eb7dd0a833e767ce2f699c9b9ae83219b81`. The six pre-existing MPF relocation
edits and ignored waveform scripts are preserved.
