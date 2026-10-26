# Internal signal names

RAINCloud Digital | RAINCloud_SAP | J. Campbell

The active RTL uses descriptive internal signal names in place of Quartus
schematic-export identifiers. Names were chosen by tracing each connection
and Boolean expression. The 190 module-scoped renames cover 10 RTL files,
including all remaining `SYNTHESIZED_WIRE_*`, `*_ALTERA_SYNTHESIZED`, and
`gdfx_temp*` identifiers, plus related register and datapath aliases.

## Conventions

- Internal signals use lower-case words separated by underscores.
- `_enable` describes an active-high control; `_n` denotes an active-low
  signal or Boolean complement. Existing external module port names remain.
- `_value` denotes stored data, `_load_data` the register input path, and
  `_bus_output` a gated output. Core bus sources use names such as `alu_bus`.
- Arithmetic names identify the bit, nibble, carry, or zero-test function.
  Bit 0 is the least significant bit. For the 74LS173 and 74LS283 models,
  it corresponds to the device's pin-name index 1.
- The 74LS161 retains its JK gate model: `bit0_j` / `bit0_k` are excitation
  signals, and their masks select load data or a count toggle.
- The 74LS283 retains its negative-logic carry network: `generate_bit0`
  is A1 AND B1, `kill_bit0` is NOR(A1, B1), and `carry4_block_bit0` names
  a term that prevents a carry from reaching the output.

## Examples

| Module | Previous name | Current name | Role |
| --- | --- | --- | --- |
| BE_8_BIT_Computer | gdfx_temp0 | data_bus | Shared 8-bit CPU datapath |
| BE_8_BIT_Computer | SYNTHESIZED_WIRE_2 | flags_write_enable | Latch arithmetic flags |
| BE_8_BIT_Computer | SYNTHESIZED_WIRE_45 | cpu_clock | Datapath execution clock |
| BE_8_BIT_Computer | SYNTHESIZED_WIRE_44 | ram_address | Address from MAR to RAM |
| ALU | SYNTHESIZED_WIRE_11 | carry_into_high_nibble | Carry between 4-bit adders |
| ALU | SYNTHESIZED_WIRE_2 | carry_borrow_next | Next ISA carry/borrow flag |
| Program_Counter | SYNTHESIZED_WIRE_0 | pc_load_n | Active-low parallel load |
| IC_74LS283_RTL | SYNTHESIZED_WIRE_64 | carry_into_bit3 | Carry into the top sum bit |

The complete per-file mapping is in
[reference/NET_RENAMES.json](reference/NET_RENAMES.json). Generated identifiers
remain in the immutable original source snapshot and this migration record.
They are absent from active RTL and testbench signal references.

The naming pass changes identifiers and explanatory comments only. Port
interfaces, module instances, Boolean expressions, bit order, clocking, and
reset logic are preserved. CPU testbench hierarchical references were updated.
The warning cleanup preceding this pass changes the internal bus implementation
and is documented separately in VALIDATION.md.

## Bus display naming — 2026-10-15

After the initial 190-net naming pass, J. Campbell approved a separate
clarification of the diagnostic bus-sampling path:

| Item | Previous name | Current name |
| --- | --- | --- |
| Sampler module | `Data_Bus` | `Bus_Display_Register` |
| Active source file | `rtl/data_bus.v` | `rtl/bus_display_register.v` |
| Core instance | `b2v_DB` | `bus_display_register` |
| Sampled-value input on `JC_Display` | `Data_Bus` | `Bus_Display_Sample` |

The shared `data_bus` net, sample net `bus_display`, sampler ports, capture
logic, and display behavior are unchanged. The Quartus and simulation source
lists use the renamed file. This later update intentionally changes the
module/instance name and one display port name; it is separate from the
port-preserving net mapping above. The original reference snapshot retains
its historical names and hashes.
