# Timing profile and qualification boundaries

The modeled device is ISSI IS42S16320F, 32M x 16, four banks, 8192 rows/bank,
1024 columns/row. The saved ISSI Rev. B1 (2017-07-17) family datasheet is in `docs/`;
the [-7 timing table](https://www.issi.com/WW/pdf/42-45R-S_86400F-16320F.pdf)
is on page 17, initialization on page 20. Confirm the installed package marking
before claiming qualification for another speed/temperature grade.

| Limit | Datasheet -7 | Implemented 50 MHz setting |
|---|---|---|
| Initialization wait | >=100 us | 200 us plus command overhead |
| Mode | programmable | CL3, sequential full-page mode, eight initialization refreshes |
| tRCD | >=15 ns | 2 cycles parameter; scheduler waits at least tRAS before access |
| tRAS | >=37 ns, <=100 us | 3 cycles minimum parameter; closes each physical segment |
| tRP | >=15 ns | 2 cycles parameter |
| REF-to-REF / tRC | >=60 ns | 4 cycles refresh recovery parameter; closed-page segments exceed tRC |
| Write recovery tDPL | >=14 ns | 2 cycles parameter before explicit precharge |
| Mode recovery | >=2 clocks | TMRD=2, with conservative FSM overhead |
| Standard refresh | 8192 commands / 64 ms | early scheduling before 380-cycle deadline (7.6 us) |

The scheduler starts refresh early enough to finish any in-progress physical segment of at most 256 words.
It never waits for a laptop or a stalled ready/valid channel to refresh. The
regression separately checks the refresh deadline. An aligned 1024-word request is four terminated bursts; row crossings can add a
fifth segment. Refresh admission reserves 280 cycles before starting a maximum
segment, so no single 20.48 us full-row burst delays refresh. Cycle parameters include extra
FSM overhead; they are lower-bound settings, not an assertion of peak throughput.

Commercial parts apply through 70 C; Industrial/A1 through 85 C. The A2 profile
above 85 C requires 8192 refreshes / 16 ms and is **not** the default supported
profile. The earlier fixed interval of 1117 cycles at 100 MHz was too long even
for 64 ms refresh. The new default is deliberately tied to 50 MHz; changing the
clock requires recalculating initialization, refresh and all other limits.

`rtl/board/de10_clock.v` is the Intel-specific PLL boundary: 50 MHz core and a
50 MHz forwarded SDRAM clock nominally +8 ns. Physical command/data outputs are
registered. A dedicated, unconditionally clocked DQ input register precedes the
read buffer. Simulation uses both nominal +8 ns and +10 ns clocks. Timing analysis
uses the actual fitted PLL, clock paths, pads and I/O registers.

`constraints/de10_lite_50mhz.sdc` constrains SDRAM input and output paths relative
to the forwarded clock at the clock pin. It uses tAC=5.4 ns max, tOH=2.5 ns min,
external setup=1.5 ns and hold=0.8 ns, plus a conservative 0.5 ns trace-skew
allowance. This allowance is an engineering assumption, **not** a measured board
flight-time extraction. Do not generalize timing closure to a new PCB without
its actual clock/data flight times and loading. PLL phase is not a timing exception.

Only asynchronous switches/buttons into their first synchronizer stages and human
indicator outputs are false-pathed. SDRAM paths are timed. The JTAG profile covers
USB-Blaster at 10 MHz or slower, with TDI/TMS launched on falling TCK and 20 ns
external timing allowance. Generated JTAG IP supplies its clock-domain crossing
constraints. The build script rejects failing or incomplete setup/hold constraints.

Compilation, functional simulation, static timing, board testing at ambient, and
temperature/voltage margin testing are distinct evidence. The last is not provided
by a desktop functional test. See `VALIDATION.md` for observed results.

Controller 1.2 constructs the mode word from named fields and the `CAS` parameter;
the same parameter sets the capture pipeline. CAS=2 and CAS=3 have model coverage.
Only the unchanged CL3 profile is used for the released board build. Supporting
CL2 in the RTL does not establish a CL2 board timing or margin qualification.
The fixed sequential/full-page/burst-write fields are scheduler requirements.
Request size and byte enables can change on every request without changing MODE.
