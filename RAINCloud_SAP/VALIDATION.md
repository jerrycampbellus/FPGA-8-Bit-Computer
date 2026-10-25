# Validation record

RAINCloud Digital | RAINCloud_SAP | J. Campbell

Last updated: 2026-10-20. Revision: 0.1.0 development.

Current revision includes warning remediation, RAINCloud Digital attribution,
descriptive signal names, architecture graphics, and the `Bus_Display_Register`
module rename, plus two-digit hexadecimal C output. Active code/configuration
files credit RAINCloud Digital and J. Campbell. The README company description is based on
raincloud.digital. All 23 original reference hashes and 13 imported vendor
notice blocks remain unchanged.

The 190 identifier substitutions across 10 RTL files are recorded in
reference/NET_RENAMES.json and explained in NET_NAMES.md. Reversing those
substitutions restores the pre-rename Verilog tokens exactly (comments and
whitespace excluded); the naming pass did not change logic or interfaces.
The CPU testbench's hierarchical references were updated consistently.
Evidence: build/naming_audit.log. The final implementation was rebuilt and
simulated after the warning fixes and naming changes.

**Quartus full compilation, fitted timing, and all five Questa functional
regression suites pass. Hardware qualification remains pending.**

| Check | Acceptance criterion | Result | Evidence |
| --- | --- | --- | --- |
| Project structure | All sources exist, unique module names, no absolute active RTL paths, simulation/build source lists agree | PASS | scripts/check_project.py; 21 modules |
| Board mapping | All 71 expected ports have unique physical pins and IO standards; 58 outputs have explicit 8 mA drive | PASS | constraints/de10_lite_pins.qsf; structural check and fitted output table |
| Program image | 16 valid bytes; explicit ascending initialization | PASS structural and runtime image-order check | programs/ram_init.hex; rtl/ram.v; tb_cpu |
| Original source preservation | All 23 reference file hashes match their import manifest | PASS | reference/SOURCE_MANIFEST.json; structural check |
| HDL/testbench compilation | All 21 design modules and five benches compile without diagnostics | PASS, 0 errors / 0 warnings | Questa 2025.2 vlog; build/questa/compile.log |
| Full Quartus compile | Synthesis, fit, assembler, timing complete | PASS, 0 errors / 9 expected warnings (previously 72) | Quartus 25.1std.0 Build 1129; build/compile.log; build/quartus/RAINCloud_SAP.sof |
| Timing constraints | Clock/synchronizer targets resolve; no unconstrained internal clock paths; setup, hold, recovery/removal and pulse width pass | PASS, 0 errors / 0 warnings | build/quartus/RAINCloud_SAP.sta.rpt and .sta.summary |
| Functional simulation | All five regression benches explicitly report PASS | PASS; 0 compilation/elaboration/simulation errors or warnings | build/questa/regression.log and tb_*.run.log |
| Board tests | Manual/continuous execution, reset after HALT, expected arithmetic/branch/output behavior | NOT RUN | Board procedure below |

Publication check on 2026-10-15 at 14:19 Eastern: a fresh local Git clone,
containing no prior build databases or local programmer chain, passed the
structural/path-case checks, all five Questa suites, and a complete Quartus
compile. Simulation had zero errors/warnings; Quartus retained the same nine
expected warnings and zero timing warnings. All 23 original snapshot hashes
also matched after checkout. Only publication documentation changed between
that check and the initial public source baseline. The later architecture and
display-register update was revalidated as recorded next.

## C display digit count — 2026-10-20

The C (OUT) view now blanks HEX2 in hexadecimal mode, showing two numeric
digits on HEX1:HEX0. Decimal retains all three digits, including leading zeros.
The C label and sign position remain fixed. The output register's stored value
and 17-bit formatted payload are unchanged.

- Structural check: PASS; 21 modules, 71 pins, 16 program bytes, and all 23
  original source hashes.
- Questa: all five regression suites PASS with zero errors and warnings.
  `tb_output` checks actual six-digit segment patterns for all 1,024 value,
  signed/unsigned, and hex/decimal combinations, mode changes with the CPU
  clock stopped, asynchronous reset in both formats, and mode independence
  of all 15 other display selectors. Evidence: `build/questa/regression.log`.
- Quartus 25.1std.0 Build 1129: full compilation PASS with zero errors and the
  same nine expected warnings described below. Timing analysis reports zero
  errors and warnings. Utilization is 876 logic elements, 285 registers, and
  71 pins. Evidence: `build/compile.log` and
  `build/quartus/RAINCloud_SAP.sta.summary`.
- Minimum timing slacks across analyzed corners: setup 8.991 ns, hold 0.132 ns,
  recovery 14.657 ns, removal 0.424 ns, and minimum pulse width 9.326 ns.
- Rebuilt `build/quartus/RAINCloud_SAP.sof`: 3,216,581 bytes; SHA-256
  `700f6fae2afcb7453144c15c8fec8009cd5ded15739463a74279383efb497d4f`.
  The generated image remains excluded from Git. No board programming or
  hardware observation was performed.
- Publication scope: the display fix, its regression coverage, and companion
  documentation. J. Campbell requested the Git update on 2026-10-20.

## Architecture and bus display rename review — 2026-10-15

The update adds documentation, SVG/PNG graphics, and a Python diagram generator,
and renames `Data_Bus` to `Bus_Display_Register`. Its source file and instance
are renamed, and the receiving `JC_Display` port is now `Bus_Display_Sample`.
The Quartus and simulation source lists use the new file path. This supersedes
the earlier documentation-only review scope.

- Structural check: PASS; 21 modules, 71 pins, 16 program bytes, and all 23
  original source hashes.
- Logic-preservation check: reversing the three identifier renames makes all
  21 active RTL files match the public baseline's executable tokens exactly.
  Comments and whitespace are excluded from this comparison. Source-list
  changes are limited to the renamed file path. Pins, timing constraints,
  program bytes, all 13 Intel notices, and author attribution are preserved.
- Module map: all 21 active RTL module types appear exactly once with links
  to their implementing files. The six bus-source names and eight capture
  controls agree with the core wiring.
- Documentation links: 56 relative links across 12 Markdown documents resolve
  with exact path case, including the README's architecture-section anchors.
- SVG generation: deterministic; both files parse as XML and include accessible
  titles/descriptions, with no external assets or scripts.
- PNG exports: dimensions match their SVGs and both files exactly match a fresh
  render. Visual inspection confirmed the new module name fits and all shared-bus
  connections have descriptions beside their lines.
- Timing/microcode review: the guide follows the active T0–T4 decode, CPU edge
  phases, flag lifetime, independent display tick, and bus sampler reset behavior.
- Questa 2025.2: all five existing suites passed after the rename at 15:00 Eastern,
  with zero compilation/elaboration/simulation errors or warnings.
- Quartus 25.1: full compile completed at 15:01 Eastern with zero errors and the
  same nine documented warnings. Timing analysis completed with zero errors or
  warnings. Utilization remains 870 logic elements, 285 registers, and 71 pins;
  minimum timing slacks match the table below.
- Current generated SOF SHA-256:
  `6bc103163ff22c952f0e898f73f37d698ed7df9d123a6057f610c9d6a3729854`.
  The generated image remains excluded from Git; no board programming was done.
- Publication review: no stale sampler names remain in active RTL, source lists,
  or graphics. Historical names remain in the provenance and migration records.
  Generated outputs, simulator licenses, credentials, and local chains remain
  excluded from the publication file set.
- Local audit summary: `build/architecture/final-review.log` (generated,
  excluded from Git). The earlier `review-checks.log` records the first diagram
  draft. J. Campbell approved the final review copy for commit and publication
  on 2026-10-15. Hardware validation remains pending.

## Quartus 25.1 results after warning cleanup and signal renaming

Full compilation completed on 2026-10-15 at 13:59 Eastern time. The design uses
870 of 49,760 logic elements, 285 registers and 71 pins. Assembler generated
`build/quartus/RAINCloud_SAP.sof` (3,216,581 bytes), SHA-256:
`b10fc6ab0c6fd26bfff85db2bc17d23fdb326f886e0a41206fa92780221b737c`.
The board was not programmed.

The first build exposed a latch caused by assigning `CLK_SELECT` during an
asynchronous reset of `manual_mode`. A fixed reset value and the existing
synchronous mode handover removed that latch. The rebuilt timing report has
zero unconstrained clocks, input paths, and output paths. All checked SDC
object counts resolve. The human-indicator output exceptions and first-stage
input synchronizer exceptions remain as documented in the SDC.

Minimum slack across both clocks and all three analyzed timing corners:

| Check | Minimum slack (ns) |
| --- | ---: |
| Setup | 8.436 |
| Hold | 0.132 |
| Recovery | 16.377 |
| Removal | 0.422 |
| Minimum pulse width | 9.327 |

TimeQuest found 12 two-register synchronizer chains, but did not calculate
MTBF; no quantitative metastability reliability claim is made. Board electrical
operation remains subject to hardware validation.

## Warning disposition

Quartus warnings decreased from 72 to 9. No message suppression, warning
waiver, or relaxed timing constraint was added.

| Original warning(s) | Resolution |
| --- | --- |
| 10036: unused ALU wire | Removed the unused inverted flag-enable net. |
| 13046 / 13047 / 13049: internal tri-state conversion | Added FPGA_MODE to the 74LS245 primitives and RAM; active SAP instances use zero for disabled outputs. Six separately gated sources feed one explicit OR-combined CPU bus. The sampled bus display also uses zero when disabled. |
| 13027 / 13028: always-disabled B-register output buffer | The FPGA-mode B path is ordinary gated logic, so an unused source optimizes away without an I/O-buffer warning. The B output interface is retained and exercised in simulation. |
| 12241: missing structural connections | Tied unused MAR buffer inputs low and explicitly left unused MAR/PC outputs open. Removed conflicting, unused upper-bit MAR input tie-offs. |
| 15714: incomplete I/O assignments | Set all 58 LED/segment outputs to 8 mA, matching the previous fit. The final fitted output table confirms all 58 still use 8 mA; pin locations and voltage standards are unchanged. |
| 24 Questa CPU elaboration warnings | Explicitly connected or marked unused structural ports and unobserved CPU display outputs in the testbench. All five suites now report zero warnings. |

The remaining nine Quartus warnings are expected and remain visible:

| ID | Count | Disposition |
| --- | ---: | --- |
| 13024 / 13410 | 7 | One summary and six HEX[7] pin messages. These active-low decimal-point outputs intentionally remain high (off); integer display formatting does not use decimal points. |
| 292013 | 1 | Quartus Lite reports that LogicLock requires a subscription. This project has no user LogicLock region assignments, and the fitter reports no reserved LogicLock region. Compilation succeeds without that feature. The installed Quartus message help says no action is required when the feature is not needed. This is separate from the working Questa Starter license. |
| 169177 | 1 | Automatic MAX 10 advisory for the 13 board inputs using 3.3-V standards. Keep the correct board standards; this is not a missing pin assignment or timing violation. Intel's support article describes this automatic message and recommends ignoring it. Hardware testing remains pending. |

References: [Intel warning 169177 support article](https://www.intel.com/content/www/us/en/support/programmable/articles/000076905.html);
installed Quartus help, `C:\altera_lite\25.1std\quartus\common\help\webhelp\msgs\msgs\wcpt_feature_disabled_post.htm`.

An idle CPU bus is now deterministically zero instead of high impedance.
The disabled bus-display sample is likewise zero. Normal register loads retain
the selected source's value. Regression assertions require exactly one source
for each active load, reject multiple/unknown enables, and check all six bus
sources plus idle while halted. Exhaustive ALU tests also verify the disabled
bus output for every operand/mode combination. The primitive default mode
continues to model high impedance for standalone 74LS245/RAM use.

## Questa 2025.2 functional results after license renewal

The recorded regression used a valid `intelqsimstarter` license and the runner's
explicit `--license` option. Each user must configure their own simulator
license. No license contents or host identifiers are stored in this repository.

The runner now maps the logical `work` library in `build/questa/modelsim.ini`,
uses Windows-compatible forward-slash paths, and executes a Tcl batch macro.
This resolved the initial library-path/elaboration startup errors. Compilation
reports zero errors and zero warnings. Each suite executes through its final
explicit PASS marker and exits successfully:

| Suite | Result | Evidence |
| --- | --- | --- |
| Clock/divider/manual/reset | PASS | build/questa/tb_clock.run.log |
| Synchronizers/debounce/reset release | PASS | build/questa/tb_inputs.run.log |
| ALU: 131,072 arithmetic/flag cases | PASS | build/questa/tb_alu.run.log |
| Output: 1,024 value/mode formats | PASS | build/questa/tb_output.run.log |
| CPU: 11 programs and bus assertions | PASS | build/questa/tb_cpu.run.log |

All five suites report zero errors and zero warnings, including CPU
elaboration. These are RTL functional simulations, not post-fit timing
simulations or hardware measurements.

Historical license failures were caused by an unset `SALT_LICENSE_SERVER` and
older licenses expired on 2026-04-15 and 2026-03-01. The renewal and successful
checkout supersede that blocker. Reference:
[Altera Questa licensing instructions](https://docs.altera.com/r/docs/683472/25.3/altera-fpga-software-installation-and-licensing/questa-altera-fpga-edition-and-questa-altera-fpga-starter-edition-software-license).

## Historical environment blockers

Earlier attempts with Quartus 23.1 and an expired Questa Starter license did
not complete implementation or simulation. Windows Smart App Control blocked
the old Quartus `ip-catalog.exe` helper, producing error 112002. A portable
Icarus installation was also blocked on the validation machine.

Updating to Quartus 25.1 and Questa 2025.2, then renewing the simulator license,
resolved the verified workflow without disabling Windows security settings.
The error's doubled slash in the helper path was not the cause. The successful
build and simulation results above supersede those earlier blocked attempts.

Use the commands below with your own installed tools and valid simulation license.

## Commands and required evidence

```powershell
python scripts/check_project.py
.\scripts\compile_questa.ps1
python scripts/run_tests.py --simulator questa --bin C:\altera_lite\25.1std\questa_fse\win64 --license C:\path\to\renewed_license.dat
.\scripts\build.ps1
```

Build/check scripts locate the project root themselves. Generated logs and
databases are local under `build/` and ignored by Git; this record summarizes
the observed results. The timing file checks expected object counts and raises
an error instead of silently accepting missing clock or synchronizer targets.
No timing warnings have been waived as a substitute for analysis.

## Regression coverage executed (all PASS)

- `tb_clock`: eight divider settings, exact phase complement, manual press/hold/
  release, HALT gating, reset with no CPU clock, and a held key after reset.
- `tb_inputs`: switch synchronization, rejection of a brief key bounce, stable
  key press/release, asynchronous reset assertion and two-cycle release.
- `tb_alu`: 131,072 A/B/add/subtract combinations; carry/borrow/zero flags,
  enabled/disabled bus outputs, flag retention when disabled, asynchronous reset.
- `tb_output`: 1,024 byte/mode combinations, signed boundaries, BCD/hex,
  formatting changes without CPU clocks, asynchronous output reset.
- `tb_cpu`: 11 programs covering ADD/SUB, taken/untaken JZ/JC, borrow,
  retained flags across LDA/STA, OUT, self-modifying STA, JMP, PC wrap, NOP,
  undefined-opcode halt, short reset after halt, and manual execution. Assertions
  reject simultaneous or unknown bus enables, require one source for every
  active load, and reject unknown captured data. Directed checks exercise all
  six bus sources (including B) and the zero-valued idle bus after each program.

## Board procedure after simulation and timing pass

1. Configure the successful SOF using the usual DE10-Lite programming process.
   This task did not program the board.
2. Select OUT display (SW7:4 = 1000), unsigned decimal, 1 Hz continuous clock.
   Reset and observe the supplied counting program.
3. Select manual mode with KEY1 released. Verify exactly one microstep per
   press/release, with both LEDR0 phases and progressing PC/instruction displays.
4. Load a small arithmetic/OUT/HLT image and verify the expected result remains
   visible while halted. Change signed/hex display modes while halted.
   In the C view, confirm HEX2 is blank for hex and shows the hundreds digit
   for decimal, with the C label and sign position unchanged.
5. At slow speed, tap reset after HALT. HALT, PC, registers and flags must clear
   without needing a full slow-clock period. Remember that reset retains RAM.
6. Test all speed settings and transitions between manual/continuous operation.
   Log board revision, tool version, program image hash, results and any failures.

Hardware sign-off remains open until these results are recorded.

## Local accelerator exploration — 2026-10-15

Scope: architecture records, dependency inspection and a software reference on
`explore/ai-edge-accelerator`, based on SAP commit
`5c68660ba5244cbdc1450fba62fa361590deac7e`.

- PASS: `scripts/check_project.py` reports 21 modules, 71 pins, 16 program bytes
  and all 23 original source hashes.
- PASS: `scripts/matrix_demo_reference.py --self-test` checks a hand-calculated
  2 × 2 result, identity/add behavior, signed extrema, byte packing, payload
  lengths and out-of-range input rejection. Generated seven directed and 100
  seeded random 4 × 4 reference cases under `build/ai_edge/reference_vectors.json`.
  These are software expected results, not accelerator simulation results.
- PASS: 22 local links in the exploration and touched overview records resolve.
  All 36 hashes captured in `docs/ai_edge_sources.json` match current dependency
  files at inspection. Of 31 source inputs compared with the saved SDRAM release,
  30 match; `quartus_project/SDRAM_Test_Harness.qsf` differs. Controller RTL and
  the other captured source inputs match that release.
- PASS: active RTL, constraints, Quartus project, program, existing benches,
  original reference, baseline architecture/images and notices match the SAP
  base commit. HEAD, local main and origin/main remain at the supplied baseline.
- No new RTL simulation, Quartus compilation, programming or board test was
  performed for this documentation/software exploration. Existing SAP results
  above remain historical baseline evidence; SDRAM release results belong to
  its separate build. Combined-design validation is planned in the
  [staged proposal](docs/AI_EDGE_ACCELERATOR.md).
