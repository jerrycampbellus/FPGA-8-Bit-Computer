# Register API 1.1

Little-endian 32-bit words, **byte addresses**, 4-byte alignment. Avalon reads return
one cycle after acceptance; waitrequest is always zero. Ordinary writable registers
honor byteenable. Commands require all four bytes enabled. Unknown reads return
0xdeadbeef; unknown writes are ignored. Only one host writer is supported.

| Offset | Register |
|---|---|
| 0x00 | Magic 0x5344524d (`SDRM`) |
| 0x04 | API major/minor 0x00010001 |
| 0x08 | Build ID 0x26101404 (source validation record identifies the exact build) |
| 0x0c | Capabilities 0xff: local, host, masks, stalls, error log, staging, retention gap (bits 0..6); page transfers (bit 7) |
| 0x10 | Live status: busy bit 1, done 2, stopped 3, initialized 4, remote owner 5, failed 6, stop pending 7 |
| 0x14 | Write command; read most recently acknowledged complete command word |
| 0x18 | Command error: 0 accepted, 1 busy, 2 invalid/not initialized, 3 ownership, 4 unknown opcode |
| 0x1c | FPGA clock frequency, Hz |
| 0x20..0x3c | Start byte address, word count, repeat count, pattern, seed, logical burst words, stall flags, phase gap cycles |
| 0x40, 0x44 | Staging memory byte address and count (1..1024) |
| 0x48 | Live refresh count (wraps at 32 bits) |
| 0x4c | Snapshot generation (wraps at 32 bits) |
| 0x50 | Live run ID (increments for tests and staging operations) |
| 0x54 | Board display readback: tag bits 23..20, five hex digits bits 19..0 |
| 0x58, 0x5c | Maximum request words (1024), page staging base (0x1000); valid when capability bit 7 is set |
| 0x80..0xbc | Frozen result snapshot, below |
| 0x100..0x13c | Compatibility alias for the first 16 page staging entries |
| 0x180..0x1bc | Frozen first eight errors, alternating address and expected/actual words |
| 0x1000..0x1ffc | 1024 staging entries, 32-bit spacing: data[15:0], byte enables[17:16] |

Command word = `(nonce24 << 8) | opcode`. Opcodes: 1 start, 2 controlled stop,
3 snapshot, 4 staged read, 5 staged write, 6 claim remote ownership, 7 release.
Read the previous acknowledgement and increment its upper 24 bits for the next
command. Re-delivery of the **identical last command word** is ignored, including
after completion. This deduplicates the immediately previous command only, not a
history of old nonces. Acknowledgement means accepted/rejected, not run completion.
Inspect 0x18 after matching the acknowledgement. A timed-out mutation must not be
blindly retried with a new nonce.

Configuration and staging writes are ignored without remote ownership or while
busy. The Python API checks idle and verifies configuration readback. Start validates
the entire range and latches the configuration. Claim is rejected during a local
run. Release is rejected while busy. Local controlled stop and host stop are always
available. A disconnected laptop leaves the FPGA running and owner unchanged.
Reconnect reads magic/version/build/status; it does not reset or clear results.
Use release after completion, or SW9+KEY0 in browse mode, to return ownership locally.

## Page transfers

`Tester.read(address, words)` and `write(address, data, byte_enable=3)` accept
1..1024 words at an even byte address. Each call issues exactly one staged-memory
command and increments run ID once, including a full page. Range validation
rejects requests beyond memory before claiming ownership.

Optional `write(..., byte_enables=[...])` supplies one two-bit mask per word,
overriding the uniform mask. Bit 0 enables the low byte, bit 1 the high byte;
00 preserves both bytes while still consuming a word beat. Mask counts/values
are checked before ownership or staging changes. Request size and byte enables
do not change the SDRAM MODE configuration.

`read_page(address)` returns exactly 2048 bytes. `write_page(address, data)`
requires exactly 2048 bytes. These convenience methods require a 2048-byte-aligned
address; words are encoded little-endian. General word methods also support
unaligned-to-page transfers across rows/banks.

The staging RAM is not initialized on reset. Fill every requested write entry,
including its byte enables, before command 5. Host staging writes require idle
remote ownership. Read staging after command completion; contents during an
active staged read, or during simultaneous writes, are not a coherent snapshot.
The first 16 entries remain accessible at both legacy and page addresses.

The new Python client discovers capability bit 7 and registers 0x58/0x5c. It
falls back to the old 16-word window on API 1.0 firmware and rejects larger
requests before any mutation. Older clients retain the legacy window and can
continue issuing 1..16-word commands on new firmware.

## Frozen result layout

Offsets relative to 0x80, in words:

| Index | Value |
|---|---|
| 0, 1 | Run ID, status at snapshot |
| 2, 11 | Completed word operations low/high (64-bit) |
| 3, 4 | Transferred logical bytes low/high (64-bit) |
| 5, 6 | Elapsed FPGA cycles low/high (64-bit) |
| 7 | Error count, saturates at 0xffffffff |
| 8, 9 | First failing byte address; expected[31:16], actual[15:0] |
| 10 | Error log entry count (0..8); excess errors counted but not stored |
| 12 | Refresh count at snapshot |
| 13, 14, 15 | Latched start, word count, pattern |

Command 3 freezes counters, status and the complete bounded error log on the same
FPGA edge, even during a run. Read snapshot generation before and after the block;
reject results if another host replaced it. Existing snapshots survive subsequent
runs until explicitly replaced. Live status is not a substitute for a coherent
snapshot. First-error fields are meaningful only when error count is nonzero.

Operations count each completed word read or write, including masked writes;
bytes = 2 * operations, not enabled-byte count. A normal pass uses 2*N operations;
the mask test uses 7*N. Stop drains the current logical transaction and counts it.
Elapsed cycles include generator, compare, configured stalls, gaps and refresh,
but exclude host transfer time and initialization. Reported bytes/second is tester
throughput, not the SDRAM chip's peak burst bandwidth. Counters are 64-bit; run IDs,
snapshot IDs and refresh count wrap modulo 2^32.

## Patterns

0 constant seed[15:0]; 1 incrementing seed + absolute word address + repeat index;
2 folded address XOR seed XOR repeat index; 3 walking one; 4 walking zero;
5 reproducible xorshift-derived address/seed/repeat pattern; 6 byte-mask test.
Walking patterns advance across addresses and repeat indices, so sixteen repetitions
exercise every bit even over a one-word range. Pattern 5 is deterministic test data,
not cryptography. Pattern 6 writes A55A, changes only low byte to A5, verifies A5A5,
changes only high byte to 5A, verifies 5AA5, attempts an A55A write with both lanes
disabled, then verifies unchanged 5AA5.

Flags bit 0 inserts write-data stalls; bit 1 inserts read backpressure. Gap is an
FPGA-cycle delay between passes, useful for retention/refresh tests. Logical burst
is 1..1024 (default 1024). Range endpoints need not align to logical burst length or row boundaries.

## Transport boundary and future serial option

`Transport.read32(address,count)`, `write32(address,values)`, `close()` are the only
transport operations used by `Tester`. `SystemConsoleTransport` keeps one Quartus
System Console process and uses a small numeric Tcl protocol. `MockTransport`
tests application behavior without hardware; its timing is synthetic.
The register transport permits the control bank at 0x000..0x1ff and page window
at 0x1000..0x1fff. Python splits register transfers into at most 128 entries per
Tcl/JTAG operation, keeping messages bounded. A 1024-entry staging transfer uses
eight transport operations but still one FPGA memory request. Transport chunking
does not start an SDRAM access. A failed chunk is not replayed automatically;
the page command is not sent unless all staging writes have succeeded.

A UART backend can implement the same register methods. Proposed wire framing:
magic A5 5A, version u8, opcode u8, sequence u16, payload length u16, payload, CRC32
(little-endian; CRC covers version through payload). Payload limit 512 bytes;
reply echoes sequence and contains an explicit status byte. Receiver scans magic,
validates bounded length and CRC, rejects invalid frames, caches the last sequence
and response, and does not repeat writes on retries. A disconnect or timeout must
not silently replay a start with a new sequence. No UART RTL, COM device selection,
GPIO assignment or external-adapter wiring is included in this JTAG delivery.
