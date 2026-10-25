# SDRAM performance investigation â€” 2026-10-14

**Prioritize overlapping client-buffer traffic with SDRAM activity.** Open-row
reuse is a secondary optimization for short requests with locality. Changing
MODE per application is unnecessary for either optimization. This release adds
configuration consistency, application mask support and measurement tools; it
does not implement speculative performance changes.

## Method and evidence

`tests/tb_performance.sv` runs the actual controller with the ISSI model and the
board's nominal +8 ns forwarded clock. It measures 16 writes followed by 16 reads
for each of ten request lengths, using three address patterns: sequential starts
within one row, alternating rows, and requests beginning at the last word of a row.
Its 60 measurements include **98,160 data comparisons**, refresh-deadline checks
and confirmation that MODE loads only once. Run it through `scripts/test.ps1`;
machine-readable records start with `PERF ` in `build/performance.log`.

The saved [simulation measurements](validation-config/simulation-performance.json)
count accepted request through accepted completion, inclusive. Client handshakes
and physical data beats are counted separately; all remaining cycles are overhead.
There are no client stalls. These figures describe the library, excluding tester
request setup, JTAG and host overhead. They are not hardware measurements.

`scripts/benchmark.py` independently measures the connected FPGA's test engine
using its 64-bit cycle counter. Each case writes/checks 65,536 words three times
with address pattern 2, no stalls, no retention gap, and request sizes 1..1024.
Starts 0 and 0x7fe show the effect of shifting request alignment. These are moving
ranges, so most short requests in the shifted run do not cross a row boundary.
The baseline report identifies build 26101402 and was collected before programming
26101403: [baseline hardware measurements](validation-config/baseline-hardware-benchmark.json).
Each case transferred 786,432 logical bytes with zero errors. Rates are decimal
MB/s of FPGA read + write traffic, not USB/JTAG transfer speed.

| Logical request | Start 0 | Start 0x7fe |
|---|---:|---:|
| 1 word / 2 bytes | 5.607 MB/s | 5.607 MB/s |
| 4 words / 8 bytes | 16.495 MB/s | 16.469 MB/s |
| 8 words / 16 bytes | 24.401 MB/s | 24.358 MB/s |
| 16 words / 32 bytes | 32.513 MB/s | 32.447 MB/s |
| 32 words / 64 bytes | 40.251 MB/s | 39.988 MB/s |
| 64 words / 128 bytes | 44.599 MB/s | 44.357 MB/s |
| 128 words / 256 bytes | 47.145 MB/s | 46.875 MB/s |
| 256 words / 512 bytes | 48.530 MB/s | 48.244 MB/s |
| 512 words / 1 KiB | 48.347 MB/s | 48.064 MB/s |
| 1024 words / 2 KiB | 48.324 MB/s | 48.040 MB/s |

The small dip above 256 words is consistent with segment/refresh overhead, not
a limitation on legal request size. A page remains useful for reducing command
and JTAG overhead; it is not intrinsically faster inside this buffered controller
than repeated 256-word requests.

The [26101403 repeat benchmark](validation-config/hardware-benchmark.json) also
passed all 20 cases and four mixed-size/per-word-mask application checks. Its
maximum throughput difference from the baseline was 0.0008%, consistent
with refresh alignment at run start. This refactor preserves performance; it does
not claim a speedup. The full 64 MiB retest again measured 48.325 MB/s with zero
errors; see [release validation](VALIDATION.md).

## Where the cycles go

For aligned 1024-word requests, the simulation measured an average **2118.06
clocks per request** across 16 writes and 16 reads:

| Work | Average clocks | Fraction |
|---|---:|---:|
| Client data transfer | 1024 | 48.35% |
| Physical SDRAM data | 1024 | 48.35% |
| Commands, recovery and unhidden refresh/control | 70.06 | 3.31% |

The controller collects a whole write request before starting SDRAM, and captures
a whole read request before delivering it. Those two 1024-cycle data phases do
not overlap. Even eliminating every remaining overhead cycle would limit this
architecture to **50 MB/s** at 50 MHz. The physical 16-bit data bus has a theoretical
**100 MB/s** data-only ceiling, before any commands, refresh or direction changes.
The earlier full-memory board result of 48.325 MB/s is consistent with this model.

## Open-row reuse

The profiler counts a reuse candidate when an ACTIVE targets the same bank/row
as the previous ACTIVE, with no intervening refresh. These are opportunities
for a future open-row policy, not actual row hits in the current controller.
Every current segment ends with PRECHARGE ALL.

| Same-row workload | Candidates / ACTIVE commands | Average clocks/request |
|---|---:|---:|
| 1 word | 25 / 32 | 16.81 |
| 16 words (32-byte cache line) | 16 / 32 | 47.69 |
| 64 words | 0 / 32 | 142.56 |
| 1024 words (2 KiB) | 0 / 128 | 2118.06 |

Alternating rows produced no candidates. Large requests produced none even with
the same-row address pattern: the current refresh policy refreshes between their
physical segments or between requests. It reserves a worst-case **280-cycle**
segment budget and therefore asserts `refresh_due` at age **100**, even while idle,
collecting a write, or serving a short request. This conservative early-refresh
policy limits row reuse more than the 380-cycle external deadline alone would.

A future open-row design should admit work using its actual bounded segment
duration, while reserving time to terminate, recover, precharge and refresh. It
must track the open bank/row and minimum/maximum active times, close on row misses
and refresh, and preserve read/write turnaround and client-stall independence.
The candidate counts above would change with that scheduler; they are not speedup
predictions. Retaining a row alone is unlikely to improve page-streaming throughput
materially under the present policy.

## Recommended next implementation

Keep the full-request RAM capacity and one outstanding logical request. Add
segment readiness and drain tracking so a complete **256-word write segment** can
run while the client fills later segments; expose completed read segments while
later segments are fetched. A physical burst still starts only when all its write
data or read-buffer capacity is available. Long client stalls must leave the
command scheduler free to precharge and refresh. Per-word masks, row crossings,
stable stalled read data and one completion after all accepted beats remain required.

For a continuous aligned page, a simple projection overlaps 768 of the current
client cycles with physical transfer. Holding today's measured overhead constant
gives `2118.06 - 768 = 1350.06` clocks, or approximately **75.85 MB/s** (1.57x).
This is an **analytical estimate, not implemented or measured performance**.
Refresh phasing, buffer-port scheduling, read prefetch and tester overhead will
change it. Short requests gain less from segment overlap; a later open-row and
segment-aware refresh change should be evaluated separately for cache/CPU workloads.

Before accepting that optimization, rerun all existing masks/boundaries/stall
tests, add stalls exactly at segment handoffs and simultaneous RAM read/write
checks, verify 380-cycle refresh spacing, close timing, and repeat the hardware
request-size and full-memory measurements. Runtime MODE switching and a CL2 board
profile remain separate work, with no demonstrated need for either in these results.
