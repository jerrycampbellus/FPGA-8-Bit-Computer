# Page-transfer validation — 2026-10-14

Firmware **26101402 / API 1.1** accepts 1..1024 words (up to 2 KiB) in one
controller or staged-memory request. The new bitstream was programmed on the
DE10-Lite and passed page transfers and a complete 64 MiB write/read test.
The earlier BL1 build and evidence remain in [VALIDATION_BL1.md](VALIDATION_BL1.md).

## Implementation and compatibility

The request count is now 11 bits. Synchronous RAM stores a complete read page
or write page with per-word byte enables. The SDRAM is programmed for sequential
full-page mode, with real bursts terminated after at most 256 words or at a row
boundary. An aligned page therefore uses four physical bursts under one request
and one completion. Refresh admission reserves enough time to finish a segment
before the 380-cycle deadline.

The register API adds a 1024-entry staging window at 0x1000..0x1ffc, capacity/base
discovery registers and capability bit 7. The legacy 16-entry window still aliases
the start of this RAM. Python detects old firmware limits, supports 1024-word
read/write calls, and adds aligned 2048-byte read_page/write_page helpers and
binary-file CLI commands. Bounded JTAG chunks populate/drain staging RAM; they
do not create separate FPGA memory requests.

## Simulation and host regression

All **three RTL suites and 24 Python tests passed**.
[Regression output](validation-page/regression-summary.txt) records:

- 17,191 controller comparisons, including lengths 1..1024, continuous transfers,
  per-beat byte masks, response/completion stalls, row/bank/end boundaries and
  adjacent-word guards. Command monitoring verifies actual segmented bursts and
  matching termination commands. Refresh spacing is checked against 380 cycles.
- Single-request page reads/writes through the tester, pipelined Avalon staging
  reads, the legacy alias, partial register byte writes, all seven patterns with
  1024-word chunks and a one-word tail, controlled page stop, ownership and errors.
- Board reset, keys, default 1024-word request, display/page controls and stop.
- Python page/word round trips, binary files, masks, bounds checked before mutation,
  capability fallback, 128-entry transport chunking, and no replay after partial
  transport failure, alongside the existing API/transport tests.

The existing ISSI model reported no timing errors. Icarus 13.0 was used; the
installed Questa simulation license remains expired.

## Build and static timing

Quartus Prime Lite 23.1std.1 Build 993 compiled the design for
MAX 10 10M50DAF484C7G. All reported timing corners passed.

| Measurement | Result |
|---|---:|
| Worst setup slack | +1.524 ns |
| Worst hold slack | +0.134 ns |
| Unconstrained setup/hold ports and paths | 0 |
| Logic elements | 7,214 / 49,760 (14%) |
| Registers | 3,490 |
| Embedded memory bits | 72,192 / 1,677,312 (4%) |
| PLLs | 1 |

Evidence: [timing](validation-page/final-timing.txt),
[constraint coverage](validation-page/final-unconstrained.txt),
[resources](validation-page/final-fit.txt),
[programming](validation-page/programming.txt), and
[source/bitstream manifest](validation-page/source-manifest.json).
Quartus inferred embedded RAM for all page buffers; staging read ports use
replicated RAM. Read-during-write warnings do not establish coherent staging reads
during active writes; the API requires reading staged results after completion.
Boot flash was not changed.

The controller subsequently received a RAINCloud version 1.1 header and detailed
implementation comments. Its non-comment HDL token sequence and the accepted
SOF hash were verified unchanged. The manifest preserves the original build-input
hash and records the annotated source separately under
`post_validation_documentation`; this documentation edit required no rebuild.

## Actual-board results

The [hardware report](validation-page/hardware-results.json) records:

- All seven patterns over 1025 words, two repeats, stalls and retention gaps:
  zero errors, including the final one-word chunk.
- Full 1024-word transfers at byte addresses 0, 0x800, 0x7fe, 0xfffffe,
  0x1fffffe, 0x2fffffe and 0x3fff800: passed, including masks and adjacent guards.
  Run ID increased once per page request.
- Binary page API round trip: passed.
- Disconnect/reconnect during a run, retained ownership, controlled stop and
  refresh continuing after stop: passed.
- Full 64 MiB address-pattern write/read: zero errors.

| Full-memory measurement | Result |
|---|---:|
| Run ID | 121 |
| Words tested | 33,554,432 |
| Read + write word operations | 67,108,864 |
| Logical bytes transferred | 134,217,728 |
| FPGA clock cycles | 138,870,787 |
| FPGA-measured duration | 2.77741574 s |
| Combined read + write throughput | 48,324,680 bytes/s |
| Comparison errors | 0 |

The earlier build took 18.641 seconds for the same address-pattern pass, so this
run is approximately **6.7 times faster**. This is FPGA tester throughput,
including buffering, comparison, command overhead and refresh. It is not USB/JTAG
throughput or peak SDRAM bandwidth.

With an already connected System Console, the measured host page write/read
round trips were about 1.38–1.53 seconds, including status and snapshot RPCs.
FPGA page-write operations themselves took 2117–2135 clocks (42.34–42.70 us),
including receiving the complete page from the tester.

The real CLI also wrote and read back a 2048-byte binary file:
[write result](validation-page/cli-write.json),
[read result](validation-page/cli-read.json), and
[matching SHA-256 hashes](validation-page/cli-files.json).
The [final status](validation-page/final-status.json) records idle local ownership.

## Scope and remaining limits

The 50 MHz / CL3 / +8 ns SDRAM clock profile and 0.5 ns trace-skew assumption
remain as documented in [TIMING.md](TIMING.md). This is ambient functional board
testing plus static timing, not temperature/voltage margin qualification or an
A2 high-temperature refresh profile.

The physical controls were user-confirmed on the earlier build. The current
board-level regression verifies their operation with the new page default;
no new physical-button observation is claimed.

Changes remain local and uncommitted on work/sdram-tester, based on
ed6d0eb7dd0a833e767ce2f699c9b9ae83219b81. The six pre-existing MPF relocation edits
and ignored waveform scripts remain preserved. No changes were pushed.
