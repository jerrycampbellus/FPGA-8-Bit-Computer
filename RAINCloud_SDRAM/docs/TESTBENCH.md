# RAINCloud SDRAM testbench guide

This guide describes the supported `tests/` regression for **controller 1.2.1 /
firmware 26101404 / register API 1.1**. It tests the reusable controller, tester
register engine and board integration at increasing levels of scope. Historical
`src/tb/` benches and Questa project files target the earlier design; they are
not included in this curated publication and are not selected by `scripts/test.ps1`.

## Test hierarchy

| Source / run | Design under test | Clock/model boundary | Main purpose |
|---|---|---|---|
| [tb_controller.sv](../tests/tb_controller.sv), CL3 and CL2 | `sdram_controller` | 50 MHz core, ISSI clock +10 ns | Independent data scoreboard, ready/valid behavior, mode, masks, boundaries and refresh |
| [tb_tester.sv](../tests/tb_tester.sv) | `tester_regs` + real controller | Direct Avalon/local stimulus, ISSI clock +10 ns | Register protocol, patterns, snapshots, ownership, stop and staging RAM |
| [tb_board.sv](../tests/tb_board.sv) | Production `sdram_tester_top`, tester and controller | Behavioral PLL +8 ns, inactive JTAG stub | Reset/start sequencing, local keys, status LEDs and selected display/edit behavior |
| [tb_performance.sv](../tests/tb_performance.sv) | Real controller | Unstalled client, ISSI clock +8 ns | Cycle/command accounting and row-reuse opportunities, with readback checks |

All four source benches use [the ISSI IS42S16320F model](../src/rtl/IS42S16320F.v).
The controller bench runs twice, giving **five RTL simulation runs**. The memory
model owns SDRAM behavior; the bench drives requests and checks observations.
The controller scoreboard does not read the model's memory arrays.

## Run the complete regression

From the repository root in PowerShell:

```powershell
$python = 'python' # Or the full path to your Python 3.10+ executable
./scripts/test.ps1 -Python $python
```

On another workstation, pass a working Python 3.10+ executable. The runner uses
`build/tools/ucrt64/bin` for Icarus when present, otherwise finds `iverilog` on
PATH. Override with `-Icarus 'C:/path/to/iverilog/bin'`. The optional
`python scripts/bootstrap_iverilog.py` installs the project-local Icarus runtime;
that setup needs network access. The regression itself needs neither hardware
nor Quartus. Icarus 13.0 is the recorded simulator; the installed Questa simulation
license was expired at release validation.

The runner compiles each top with SystemVerilog 2012, runs it, checks its exit
status and PASS marker, and rejects `ERROR`, `VIOLATION` or `FATAL` model messages.
It then verifies eight invalid parameter profiles fail elaboration for a named
`SDRAM_CONFIG_ERROR` guard, and runs Python `unittest` discovery under `tests/`.

`-CompileOnly` skips **only the five `vvp` executions**. It still compiles the
positive profiles, checks negative elaboration and runs Python tests. It does
not establish a new functional simulation pass.

| Output | Meaning |
|---|---|
| `build/controller.log` | CL3 controller run; expected 17,191 comparisons |
| `build/controller_cl2.log` | CL2 controller run; expected 17,191 comparisons |
| `build/tester.log` | Register-engine integration assertions |
| `build/board.log` | Board-control integration assertions |
| `build/performance.log` | 60 `PERF` JSON records and 98,160 read comparisons |
| `build/<run>.vvp` | Compiled executable for each run |
| `build/invalid-profile.log` | Most recent negative elaboration diagnostic; overwritten for each profile |
| Terminal output | PASS summaries and Python test results; redirect if a combined record is needed |

The current functional baseline is five passing RTL runs, eight expected
elaboration rejections, and **26 Python tests**. Exact accepted output is saved in
[regression-summary.txt](validation-warnings/regression-summary.txt). Comparison
counts are useful tripwires for accidentally skipped cases; they are not formal
coverage percentages. Additional guards/command assertions do not increment the
controller's data-comparison counter.

After the earlier 26101403 documentation update, the annotated HDL and runner were verified to
have identical executable token sequences to those accepted sources. Positive/
negative elaboration and all 26 Python tests were rerun with `-CompileOnly`;
the five functional simulations were not repeated for comments alone. See the
[documentation verification record](validation-config/documentation-check.json).
The 26101404 warning cleanup changes executable RTL and therefore reruns all
five simulations. It also adds checks that unknown/high/unaligned register
addresses cannot alias valid registers, high pattern IDs stay unsupported, and
incrementing data wraps correctly at 16 bits.

To compile and run only the CL2 controller bench:

```powershell
$iverilog = "$PWD/build/tools/ucrt64/bin"
$env:PATH = "$iverilog;" + $env:PATH
& "$iverilog/iverilog.exe" -g2012 -s tb_controller -P tb_controller.TEST_CAS=2 -o build/controller_cl2.vvp rtl/library/sdram_controller.sv tests/tb_controller.sv src/rtl/IS42S16320F.v
if ($LASTEXITCODE -ne 0) { throw 'Controller compilation failed' }
& "$iverilog/vvp.exe" build/controller_cl2.vvp *> build/controller_cl2.log
if ($LASTEXITCODE -ne 0) { throw 'Controller simulation failed; inspect log' }
Select-String -Path build/controller_cl2.log -Pattern 'PASS|ERROR|VIOLATION|FATAL'
```

Use `TEST_CAS=3` for the release profile. The complete runner remains the
acceptance check because it enforces both PASS and absence of model errors.

## Controller bench: drivers and scoreboard

Stimulus changes on falling core-clock edges and is accepted on rising edges
with `valid && ready`. `request()` holds the byte address, actual count and
direction until accepted. `completion()` checks the expected error, blocks
completion for 420 clocks and checks it remains asserted before acceptance.

`write_words()` starts with a 430-clock producer stall, then uses continuous
beats for counts at least 256 or patterned gaps for smaller writes. The
request-local `expected[]` array updates only on accepted beats and only in
enabled lanes. Each checked range is initialized by a full-mask write before
partial/no-op masks. `mixed_masks()` cycles 00/01/10/11 across consecutive beats.

`read_words()` holds the first read response for 420 clocks and later responses
for three clocks, checking stable valid/data/last during backpressure.
`read_continuous()` accepts a word every available clock, checking RAM prefetch.
Both compare each accepted word and `r_last`. `check_guard()` separately verifies
the fixed 0xcafe sentinels immediately outside page writes.

| Sequence | Directed coverage |
|---|---|
| Small boundary transfers | 16 words around row transitions, all bank transitions and memory end; masks 11, 01, 10 and 00 |
| Short counts | Every count 1..15; 16 is covered above |
| Segment/page counts | 17, 31, 255, 256, 257, 511, 512, 513, 1023, 1024 starting at byte 0x7fa |
| Full-page cases | Starts 0x800, 0x7fe, 0xfffffe, 0x1fffffe, 0x2fffffe, 0x3fff800; mixed masks, continuous/stalled reads and adjacent guards |
| Invalid requests | Odd address, zero count, count 1025, read/write range overflow; completion error 1 |
| Final idle interval | 1000 more clocks with the refresh monitor active |

Command monitors inspect output pins: MODE must be 0x037 for CL3 or 0x027 for
CL2, with bank bits zero and exactly one load across all requests. Initialization
must allow at least two clocks of mode recovery. READ/WRITE and BURST TERMINATE
totals must match. An aligned page write needs four access commands; the selected
row-crossing page writes need five. Refresh spacing must never exceed 380 core
clocks after initialization, including the long producer/consumer/completion stalls.

This is directed boundary coverage, not every possible length, address or stall
sequence. The 20 ms watchdog fails a deadlock. CL2 passing the model does not
qualify a CL2 board profile; the released hardware remains CL3.

## Tester bench: register-to-memory integration

`wr()` and `rd()` are a small Avalon bus driver using byte addresses and the
one-cycle read response. `command()` increments a 24-bit nonce and checks both
the echoed command and expected command-error code. `finish_run()` waits for
idle, requests a frozen snapshot and checks completed operations, logical bytes,
error count and done status. These bench totals fit 32 bits; Python tests
separately exercise decoding of 64-bit counters.

The test sequence covers:

1. Initialization identity, ownership rejection/claim, and all seven patterns
   over 33 words with two repeats, 16-word chunks, both stall flags and a
   500-clock phase gap. Configuration/local edit attempts cannot alter the run.
2. A one-bit XOR on returned data creates 33 deliberate comparison failures.
   Checks cover total errors, an eight-entry log count, full first-error address,
   expected/actual words and their display pages. This injects a checker-input
   fault; it does not model an electrical fault or ECC.
3. Snapshot persistence into a later run (the frozen run-ID word is checked),
   busy command rejection, local controlled stop and ownership retention.
4. Staged transfers at a row boundary, then a 1024-word page crossing a bank
   boundary. A request-handshake counter proves one controller request per page
   direction. Back-to-back Avalon reads check all 1024 RAM responses; legacy
   aliases, partial host byte writes and low-byte-only page updates are checked.
5. Invalid staging sizes/ranges, all seven patterns over 1025 words in 1024-word
   chunks, a controlled stop that drains exactly one page, command errors and
   duplicate last-command delivery without a new run ID.
6. Ownership release, a standalone 1024-word preset, host-claim rejection while
   the local run is active, and refresh continuing after completion.

The 30 ms watchdog bounds the run. This bench directly drives the register
interface; generated JTAG bridge logic, Tcl and USB transport are outside it.

## Board bench: local controls and model substitutions

The production top is compiled with `DEBOUNCE_BITS=2`. The bench's `de10_clock`
module passes the reference to the core, delays the memory clock by 8 ns and
asserts lock after 200 ns. Its `jtag_bridge` module leaves Avalon commands
inactive. Compile these substitutes **instead of** the real PLL and generated
JTAG modules; duplicate definitions are a setup error.

`press()` holds an active-low key for 12 clocks and releases it for 12 clocks,
allowing synchronizers and shortened debounce counters to settle. The sequence
waits for initialized, runs the default smoke test, checks 2048 word operations
and pass LEDs, checks HEX5 page 1 encoding, starts/stops another run, and edits
the burst setting from 1024 to 1 while idle. The watchdog is 5 ms.

This checks selected board wiring and local behavior. It does not exercise
physical contact bounce, all display/edit combinations, SW9 ownership release,
the three-second two-key reset, active JTAG traffic, analog PLL lock/jitter or
fitted I/O timing. See [BOARD.md](BOARD.md), [TIMING.md](TIMING.md) and the separate
[hardware evidence](VALIDATION.md) for the corresponding contracts and checks.

## Performance bench: accounting and output

The ten counts are 1, 4, 8, 16, 32, 64, 128, 256, 512 and 1024. For each count,
three address workloads run 16 writes followed by 16 reads. Expected data is a
deterministic function of byte address, so overlapping/repeated writes do not
invalidate the later reference values. No client stalls are inserted.

| JSON field | Meaning |
|---|---|
| `words`, `requests`, `read` | Words per request, requests in this case (16), direction (0 write, 1 read) |
| `workload` | 0: sequential aligned starts within one row; 1: alternating rows at 0/0x800; 2: repeated start 0x7fe (crosses a row only when words > 1) |
| `cycles` | Sum of accepted-request through accepted-completion edges, inclusive; inter-request idle edges excluded |
| `client_beats` | Accepted write input or read output beats |
| `physical_beats` | Driven write words or read RAM captures, observed using controller internal signals |
| `overhead_cycles` | `cycles - client_beats - physical_beats` for the current non-overlapping data phases |
| `activates`, `precharges`, `refreshes` | Commands observed within measured request windows |
| `reuse_candidates` | ACTIVE to the same bank/row as the previous ACTIVE with no intervening refresh; opportunity only, not an implemented row hit |

The refresh deadline and total MODE-load monitors run even outside measurement
windows. A refresh in an inter-request gap invalidates the remembered row even
though it is not counted in the case's `refreshes`. Row history also resets for
each case. Each case must have exactly `16 * words` client and physical beats,
matching ACTIVE/PRECHARGE counts and correct read data/last. The watchdog is 100 ms.

Compute decimal library MB/s as `2 * requests * words * 50 / cycles` at 50 MHz.
These figures exclude the tester engine, JTAG and host overhead. The physical
beat counters depend on the present internal capture pipeline, and overhead
subtraction assumes no data-phase overlap. Update that accounting before using
this bench to assess a future overlap or open-row implementation. Saved results
and carefully labeled projections are in [PERFORMANCE.md](PERFORMANCE.md).

## Failure diagnosis and extending coverage

For the generated-IP cleanup, run `./scripts/test_jtag.ps1` after
`./scripts/build.ps1 -Regenerate`. This optional suite checks transformation
idempotence/rejection and runs [tb_jtag_adapters.sv](../tests/tb_jtag_adapters.sv)
against renamed raw generator modules. All 1,048,576 channel/data/control
combinations must have identical output ports. This bench needs no ISSI model;
it has a 2 ms watchdog and prints `PASS jtag_adapters`. Raw copies live under
`build/jtag-raw`, so regenerate first if that directory has been removed.
See [WARNINGS.md](WARNINGS.md) for the generation hook and comparison scope.

Inspect the first model error or `$fatal` in the failing run's log, not merely
the final timeout. Check stimulus alignment/count, the expected mask/data and
ready/valid handshakes before changing timing parameters. A model diagnostic
can occur even if the final data comparisons happen to pass.

Waveform dumping is disabled by default to keep regression output small. For a
temporary debug run, add a bounded `$dumpfile("build/debug.vcd")` / `$dumpvars`
initial block to the bench or use the simulator's waveform controls. Useful
signals are request/data/completion valid/ready, address/count/masks, physical
RAS/CAS/WE/address/bank/DQM/DQ, controller `state`, `refresh_age`, `exec_index`,
`segment_words`, `burst_cycle`, and fill/capture/read indices. In tester failures
also inspect `phase`, `chunk`, `beat`, `owner`, `stop_pending` and command status.

When adding cases, preserve rising-edge handshake semantics and expected-data
independence, keep the watchdog, and update this guide and recorded comparison
counts deliberately. Keep timing/static-analysis, mock host tests and actual-board
measurements distinct. `scripts/hardware_acceptance.py` and `scripts/benchmark.py`
are separate hardware tools that overwrite selected SDRAM; the simulation runner
does not program or communicate with the board.
