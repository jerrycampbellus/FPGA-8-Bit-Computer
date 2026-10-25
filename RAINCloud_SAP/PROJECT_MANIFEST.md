# Project manifest

RAINCloud Digital | RAINCloud_SAP | J. Campbell

- Name: RAINCloud_SAP
- Original author: Jerry Campbell; documentation credit: J. Campbell.
- Project attribution: RAINCloud Digital, a limited liability company providing
  engineering, product development, intellectual-property consulting, and
  marketing services. See the website-sourced description in README.md.
- Purpose: repair and preserve the existing SAP FPGA computer as a standalone,
  reproducible DE10-Lite project.
- Revision: 0.1.0 development baseline, 2026-10-15; not hardware-qualified.
- Target: Terasic DE10-Lite, MAX 10 10M50DAF484C7G, 50 MHz oscillator.
- Scope: existing development board, FPGA RTL and verification. No new PCB,
  BOM procurement, PSpice, FreeCAD, placement, routing, or fabrication work.
- Authoritative native project: `RAINCloud_SAP.qpf` / `RAINCloud_SAP.qsf`.
- Authoritative implementation: explicit `rtl/` sources listed in the QSF.
- Architecture guide: [ARCHITECTURE.md](ARCHITECTURE.md), with system/datapath
  diagrams in `docs/images/` and their generator in `scripts/draw_architecture.py`.
- Tools: Quartus Prime Lite 25.1std.0 Build 1129; Questa Altera Starter 2025.2;
  regression runner supports Questa and Icarus Verilog 13.
- Current gate: implementation and prototype validation; see VALIDATION.md.
- Frozen for this revision: device/pins, 16-byte address space, legacy opcode
  values, core module partition, board switch assignments.
- Verified: full Quartus compilation, fitted timing under the checked-in
  constraints, and all five Questa functional regression suites. Provisional:
  board electrical operation and hardware validation. Quartus has 9 expected
  warnings; all simulation suites have zero warnings. See VALIDATION.md.
- Naming: 190 internal identifiers renamed by function without changing logic
  or ports; see NET_NAMES.md and reference/NET_RENAMES.json.
- Display naming: `Bus_Display_Register` (formerly `Data_Bus`) stores the bus
  sample; `JC_Display.Bus_Display_Sample` receives it. This later naming update
  preserves logic and is documented separately in NET_NAMES.md.
- Original source/provenance: `reference/SOURCE_MANIFEST.json`.
- Public repository: https://github.com/jerrycampbellus/RAINCloud_SAP
- Publication: source baseline on `main`; hardware qualification remains pending.
- Licensing: existing file-level notices preserved; no repository-wide
  open-source license selected. See NOTICE.md.

## Local architecture exploration

- Branch: `explore/ai-edge-accelerator`, based on the published SAP baseline.
- User-confirmed aim: small matrix multiply/add learning demo using SDRAM;
  select the eventual AI workload later.
- Exploration gate: project definition and architecture. The implemented SAP
  revision and its validation status above remain the baseline.
- Proposal and staged acceptance: [SAP/SDRAM accelerator](docs/AI_EDGE_ACCELERATOR.md).
- Deliverables: architecture, dependency inspection hashes and software reference.
  Hardware interfaces, numeric formats and performance budgets remain provisional.
- No accelerator RTL or active build changes. Local Git checkpoint requested
  on 2026-10-24; publication remains out of scope.
