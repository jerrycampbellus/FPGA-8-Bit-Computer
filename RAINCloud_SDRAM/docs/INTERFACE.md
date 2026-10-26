# SDRAM library interface, RAINCloud controller 1.2.1

`rtl/library/sdram_controller.sv` is the reusable, vendor-independent controller.
It owns initialization, mode programming, refresh, row management and physical
commands. The DE10 example supplies a 50 MHz core clock and a forwarded SDRAM
clock nominally shifted +8 ns. No CPU, Intel FIFO, or JTAG dependency exists in the library.

## Transaction contract

All signals except the SDRAM pins use rising `clk` edges. Reset is synchronous,
active high. A transfer occurs only on `valid && ready`. The producer holds valid
and payload stable until that edge. Reset cancels in-flight work; memory contents
are not guaranteed across reset. Wait for `initialized` after every reset.

| Channel | Payload and meaning |
|---|---|
| `req_valid/req_ready` | `req_write`, 26-bit **byte** `req_addr`, 11-bit `req_words` = 1..1024 (actual count, not count minus one) |
| `w_valid/w_ready` | 16-bit `w_data`, two-bit active-high `w_be`; bit 0 enables DQ[7:0], bit 1 enables DQ[15:8] |
| `r_valid/r_ready` | 16-bit `r_data`, `r_last` asserted on the final accepted word |
| `done_valid/done_ready` | `done_error`: 0 success, 1 invalid address/count; values 2..3 reserved |

Addresses must be even. The legal byte range is 0x0000000..0x3ffffff (64 MiB),
with last aligned word at 0x3fffffe. A request may cross row or bank boundaries,
but may not cross the end of memory. A 1024-word request need not start on a row
boundary; the controller splits it into the necessary physical row accesses. Invalid requests return a completion without
consuming write data or producing read data. The client must observe completion
errors while waiting for either data channel.

Exactly one transaction can be outstanding. The next request is accepted after
the previous completion handshake. Writes accept precisely `req_words` data beats
after request acceptance. There is no write-last flag to confuse with byte masks.
All write data is collected before any physical WRITE. All physical read words
fit in dedicated storage before the read response is exposed; external stalls
cannot overflow it. The completion stays valid under backpressure. Read completion
follows the final **accepted** read beat. Write completion follows the final write,
write recovery and precharge, so a later read observes the write.

Every accepted request is consumed exactly once. There is no speculative FIFO pop,
non-showahead ambiguity, hidden command queue, or externally issued mode command.
Refresh continues during write collection, stalled read response, stalled completion,
idle, and tester stop. A client that never finishes a write can block further client
transactions, but cannot block refresh.

## Physical profile

Word address = byte address >> 1. Word bits [24:23] select bank, [22:10] row,
[9:0] column. One physical row is 1024 words / 2048 bytes. The controller
defaults to CL3, sequential full-page burst mode, and burst writes (mode word 0x037).

`CAS` is the single compile-time source for both the mode register's latency
field and the read capture pipeline. The mode word is assembled from named
local parameters: `MODE_BURST_LENGTH`, `MODE_BURST_INTERLEAVED`,
`MODE_OPERATION` and `MODE_WRITE_SINGLE`. These fields describe the physical
format required by this scheduler; they are deliberately fixed local parameters.
Only CAS=2 or CAS=3 is accepted. CL2 produces 0x027 and passes model regression,
but the board release remains CL3; CL2 has not been qualified on hardware.
`TMRD` controls initialization mode recovery and must be at least two clocks.
Invalid CAS, capacity, timing-count or refresh-budget ranges fail elaboration.
These checks catch structural incompatibilities, not arbitrary board timing errors.

There is no runtime MODE write port. Initialization loads MODE once after all
banks have been precharged. Reset restarts initialization and invalidates pending
work. A future runtime mode change would need to drain transactions, close all
banks, observe recovery, load MODE and synchronize the capture pipeline before
accepting more work. Changing application request length needs none of this.

A single logical request contains 1..1024 words. The physical scheduler divides it
into segments of at most 256 words, also splitting at each row/bank boundary.
Each segment uses one ACTIVE and one READ or WRITE command, streams one word per
SDRAM clock, explicitly issues BURST TERMINATE, and precharges before proceeding.
This prevents full-page mode from wrapping into previously accessed columns.
An aligned page uses four physical bursts, while remaining one client request
with one completion. A row-crossing page can require five physical bursts.

At 50 MHz, 1024 data clocks alone take 20.48 us, exceeding this controller's
7.6 us refresh deadline. Segment admission reserves 280 cycles for the worst
256-word access, including command and recovery overhead. When fewer than those
cycles remain, the scheduler refreshes first. Refresh also continues during
write collection, response/completion stalls and idle time. No refresh debt is
accumulated and no live SDRAM burst depends on client ready/valid timing.

The write buffer stores 1024 data/mask entries; the read buffer holds 1024 words.
Both use synchronous embedded RAM, with prefetch for continuous client beats.
Buffers are not cleared on reset; validity state prevents stale data from being
returned. Reads become visible only after the entire request has been captured.

The checked profile is MAX_WORDS=1024, CAS=3, 50 MHz. Timing cycle parameters are
explicit for future board ports; arbitrary parameter values are not qualified.
See [TIMING.md](TIMING.md) for the part profile and I/O assumptions.

## Client integration examples

Applications choose **byte address, actual word count and per-word byte enables**.
The controller chooses physical burst termination, row/bank transitions and refresh.
These example requests can be interleaved without reconfiguration:

| Application operation | `req_words` | Byte enable policy |
|---|---:|---|
| Byte store | 1 | 01 for low byte, 10 for high byte |
| 32-byte cache-line fill/writeback | 16 | 11 for every write word |
| 2 KiB streaming/DMA block | 1024 | 11, or a mask per write word |
| Partial tail | 1..1024 | Application-selected masks, including 00 |

A mask of 00 preserves both bytes but still consumes one write-data beat. Read
requests return complete words; byte selection belongs to the application.
`Configuration.burst` in the tester/Python API means this logical request size,
not the SDRAM MODE burst-length field. A larger test range is automatically
divided into these requests, including a shorter final request.

For a SAP byte write, request one aligned word at `{cpu_address[25:1],1'b0}`.
For an even address, send `{8'h00,cpu_data}` and `w_be=01`; for an odd address,
send `{cpu_data,8'h00}` and `w_be=10`. Wait for completion before retiring the store.
For byte reads, request the aligned word, accept it, select the low/high byte using
the original address bit 0, then accept completion. A 16-bit CPU operation at an
odd address needs two requests; that policy belongs in the CPU adapter.

A DMA or accelerator tile client should request up to 1024 contiguous words,
collect all returned beats into FPGA RAM, and release completion before the next
request. Double-buffer tile RAM above this interface to overlap compute and the
next transfer. A cache should have explicit fill, dirty writeback and invalidate
policies. A future arbiter must retain ownership through **completion**, including
all data beats. These are optional clients; the tester implements no SAP CPU,
cache coherency, DMA engine, or matrix arithmetic.

Historical `src/rtl/SDRAM_Controller_Core.v`, wrappers and sequencer remain available
for study and baseline reproduction. They are not part of the supported new library
and retain their known defects. Use `rtl/`, not the historical AXI-like interface,
for new integrations.
Migration from the first library revision requires widening `req_words` and
client beat/count signals from 5 to 11 bits. Existing 1..16-word transactions
retain their handshake and completion semantics. The qualified maximum is 1024;
changing MAX_WORDS alone does not change the fixed page geometry or count widths.

Python uses the same application choices over the staging interface:

```python
tester.write(0x7fe, [0x1234, 0xabcd, 0x5678], byte_enables=[1, 2, 3])
words = tester.read(0x7fe, 3)  # row crossing is handled internally
```

`byte_enable=3` remains the uniform default. Optional `byte_enables` supplies one
two-bit mask per word and overrides that default. Counts/data/masks are validated
before claiming ownership or modifying staging RAM. One call is one controller
request even when the JTAG transport splits the staging transfers into chunks.
The API 1.1 register map already stores a mask per entry, so this addition does
not change firmware register compatibility.

