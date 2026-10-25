# Changelog

RAINCloud Digital | RAINCloud_SAP | J. Campbell

## C display digit count — 2026-10-20

- Hexadecimal OUT now shows two digits on HEX1:HEX0 with HEX2 blank. Decimal
  retains three digits, including leading zeros; C and sign positions are fixed.
- Routed the existing hexadecimal selection to the display decoder. Switching
  modes continues to work while the CPU is halted; other display views are unchanged.
- Extended `tb_output` to verify actual segment patterns for all 1,024 value/
  signed/format combinations, reset, and mode independence of the other views.
- Validation: all five Questa suites and fitted timing pass; full Quartus
  compilation retains the same nine expected warnings. Board testing is pending.

## Local accelerator exploration — 2026-10-15

- Added an SDRAM-backed matrix multiply/add architecture proposal, staged
  experiments, CPU integration options and measurable acceptance criteria.
- Recorded the user's learning-demo and SDRAM requirements, dependency source
  hashes and the distinction between current implementation and proposed modules.
- Added a software-only integer reference and reproducible 4 × 4 test vectors.
- Active RTL, Quartus project, constraints, baseline program and original
  reference files are unchanged. This exploration remains local to the exploration branch.

## Architecture and bus display naming — 2026-10-15

- Added a system overview at the top of the GitHub README and a detailed CPU
  datapath diagram, with editable SVG sources and matching PNG previews.
- Added ARCHITECTURE.md with all 21 modules, bus ownership and capture paths,
  clock/reset behavior, display taps, and an ADD instruction walkthrough.
- Added a standard-library Python diagram generator and PNG export notes.
- Placed connector descriptions beside their lines and labeled every shared-bus
  connection with bit widths and transfer descriptions.
- Renamed the diagnostic `Data_Bus` module/file to `Bus_Display_Register` /
  `rtl/bus_display_register.v`, its instance to `bus_display_register`, and the
  corresponding `JC_Display` port to `Bus_Display_Sample`. Updated build and
  simulation source lists, documentation, and graphics.
- Clarified the diagnostic sampler's existing lack of reset/initialization.
  RTL logic, pin/timing constraints, and program bytes are unchanged.
- Validation after rename: token-preservation and structural checks pass; all
  five Questa suites pass without warnings; Quartus compile and timing pass
  with the same nine expected build warnings. Documentation and graphics reviewed.

## 0.1.0 development — 2026-10-15

- Prepared the public source baseline with clone/build instructions, contribution
  guidance, preserved attribution notices, and portable provenance metadata.
- Corrected RAM snapshot path casing in the manifest and added exact-case path
  checks so Windows validation also catches paths that would fail on Linux.

- Corrected author credit to J. Campbell (Jerry Campbell) and added RAINCloud Digital
  attribution to active source/configuration headers and project documentation.
  Existing vendor notices and the original reference snapshot are preserved.
- Created the standalone RAINCloud_SAP Quartus project and preserved a hashed
  source baseline from BenEater_8Bit_Computer.
- Replaced absolute paths and implicit module discovery with explicit relative inputs.
- Corrected manual clock inversion, registered clock selection, and synchronized/
  debounced board inputs.
- Added reset behavior independent of halted CPU clock activity.
- Made microcode decode combinational and microstep rollover explicit.
- Captured arithmetic flags with writeback and retained them across instructions.
- Removed unintended MAR reloads during operand read/store cycles.
- Corrected output register capture/reset and signed formatting; removed
  nonblocking assignments from the combinational display decoder.
- Added timing constraints, standalone build scripts, structural checks and
  five SystemVerilog regression benches.
- Updated build scripts for Quartus 25.1 and Questa 2025.2; added a Questa
  regression backend and an optional per-run license file argument.
- Replaced the clock-mode register's variable asynchronous reset value with
  a fixed reset and synchronous mode adoption, removing an inferred latch and
  its unconstrained clock. Added a held-key-after-reset regression case.
- Corrected Questa's Windows library mapping and Tcl batch execution in the
  regression runner. Configured the renewed Starter license for the local user.
- Replaced internal tri-state inference with explicit FPGA-mode gated bus
  sources, fixed unused connections, and specified the existing 8 mA output drive.
  Idle bus and disabled sampled-bus display values are now defined as zero.
- Renamed 190 internal nets/register aliases across 10 RTL files by function,
  updated CPU testbench references, and recorded the mapping in NET_NAMES.md
  and reference/NET_RENAMES.json. The naming pass preserves logic and ports.
- Updated attribution to RAINCloud Digital and added a company description
  based on its published mission and services at raincloud.digital.
- Validation: full Quartus build and fitted timing pass with 9 expected warnings,
  down from 72. All five functional suites pass with zero warnings, down from
  24 CPU elaboration warnings. Hardware tests remain pending. See VALIDATION.md.
- Fabrication impact: none; existing DE10-Lite board only.
