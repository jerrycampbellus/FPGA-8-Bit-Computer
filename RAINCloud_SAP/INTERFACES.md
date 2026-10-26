# Interfaces

RAINCloud Digital | RAINCloud_SAP | J. Campbell

| Interface | Definition | Source of truth |
| --- | --- | --- |
| FPGA | MAX 10 10M50DAF484C7G | RAINCloud_SAP.qsf |
| Board pins / voltage | DE10-Lite mapping, 3.3 V LVTTL; keys Schmitt inputs | constraints/de10_lite_pins.qsf |
| Board clock | MAX10_CLK1_50, 50 MHz, 20 ns | constraints/RAINCloud_SAP.sdc |
| CPU phase | Rising executes datapath; falling advances microstep | rtl/be_clock.v, rtl/control_logic.v |
| Reset | KEY0 active low; async assert, board-clock synchronized release | rtl/input_conditioner.v |
| Step | KEY1 active low; 5 ms debounce, one rising/falling pair per press/release | rtl/input_conditioner.v, rtl/be_clock.v |
| RAM | 16 x 8, common instructions/data, initialized at configuration, retained across reset | rtl/ram.v, programs/ram_init.hex |
| Internal data bus | One enabled source at a time; disabled sources and idle bus drive zero; loads require one selected source | rtl/be_8_bit_computer.v, sim/tb_cpu.sv |
| Bus display register | Samples the shared bus on a CPU rising edge; captures zero when disabled; no reset input or RTL initializer | rtl/bus_display_register.v; JC_Display.Bus_Display_Sample |
| LED/segment output drive | Explicit 8 mA, matching the previous fitted build | constraints/de10_lite_pins.qsf |
| ISA | High nibble opcode, low nibble address, PC wraps at 16 | rtl/microcode_statemachine.v |
| Flags | bit 0 zero; bit 1 ADD carry / SUB borrow; bits 7:2 zero | rtl/alu.v |
| Switch/display mapping | See README board controls | rtl/RAINCloud_SAP.v, rtl/jc_display.v |
| C (OUT) digit count | SW9 drives formatting and JC_Display.CPU_Output_Hexadecimal: hex shows HEX1:HEX0 with HEX2 blank; decimal shows HEX2:HEX0; sign stays on HEX3 | rtl/be_8_bit_computer.v, rtl/jc_display.v, sim/tb_output.sv |

No external GPIO bus, custom PCB, enclosure, or mechanical interfaces are
introduced. The original 74LS-style module partition is retained. FPGA-mode
buffers feed a single OR-combined data bus, with zero on inactive paths. The
standalone 74LS245 primitives and RAM retain their original high-impedance
disabled-output behavior when FPGA_MODE is left at its default of zero.
See NET_NAMES.md for internal signal names and active-low naming conventions.
See [ARCHITECTURE.md](ARCHITECTURE.md) for the module connection diagrams,
bus-source and capture tables, display taps, and instruction timing walkthrough.
