# Standalone DE10-Lite controls

Power-up initializes memory automatically. Defaults: byte address 0, 1024 words,
one repeat, address pattern, logical transfer length 1024. No laptop is required.
The existing Terasic pin assignments are preserved in the active QSF.

With **SW0=0** (browse/run), KEY1 starts a local run if idle and locally owned,
or requests a controlled stop if running, including during a remote run. KEY0
advances the display page. SW9+KEY0 releases remote ownership while idle. Holding
both keys for three seconds resets the design and invalidates memory/results;
normal stopping should use KEY1.

With **SW0=1** (edit), SW[3:1] selects a field and SW[6:4] selects a hexadecimal
digit (0 is least significant). KEY0 increments and KEY1 decrements that digit.
For cycle/preset fields, either key advances/applies the selection. Editing is
ignored during any run or while remotely owned. The display shows the selected
field automatically: digit selections 0..4 show the low five nibbles, selections
5..7 show the upper three nibbles. HEX5 labels the field with its decimal point off.

| Field | Editing |
|---|---|
| 0 | Apply preset selected by SW[6:4]: 0=1024-word smoke, 1=entire 64 MiB, 2=32 words crossing byte 0x800, 3=1024 words with 100 ms retention gap; 4..7=smoke |
| 1 | Logical transfer length cycles 1,2,4,8,16,32,64,128,256,512,1024 |
| 2 | Start byte address, forced even and within 64 MiB |
| 3 | 32-bit pattern seed (constant data uses low 16 bits) |
| 4 | Number of 16-bit words |
| 5 | Pattern cycles 0..6; see API.md |
| 6 | Repeat count |
| 7 | Stall flags cycle 0..3 |

An invalid zero count, zero repeats, or overflowing range is rejected at start.
Host command errors expose the reason; locally correct the fields or apply a preset.

In browse mode HEX5 labels the page (hexadecimal, decimal point lit), with five
hex digits of value on HEX4..HEX0. Together pages 8 and 9 show the full first
failing byte address; pages A and B show complete expected/actual words.

| Page | Value |
|---|---|
| 0 | Completed operations low 20 bits while running; configured length when idle |
| 1, 2 | Configured start address bits 19..0 / 25..20 |
| 3 | Seed low 16 bits |
| 4 | Pattern (1 hex digit) / logical transfer length (3 hex digits) / repeat low nibble |
| 5, 6 | Completed operations bits 19..0 / 31..20 (host has full 64-bit count) |
| 7 | Error count low 20 bits (host has full count) |
| 8, 9 | First failure address bits 19..0 / 31..20 |
| A, B | Expected / actual full 16-bit data |
| C, D, E, F | Elapsed cycles bits 19..0 / 39..20 / 59..40 / 63..60 |

LED0 running, LED1 done, LED2 errors, LED3 stopped, LED4 remote owner,
LED5 initialized, LED6 stop pending, LED9 edit mode. LED7/8 are reserved.
Done with neither error nor stopped is a successful run. Stopped is not a pass.
Registers 0x10 and 0x54 expose the same status/display sources used by the board.
