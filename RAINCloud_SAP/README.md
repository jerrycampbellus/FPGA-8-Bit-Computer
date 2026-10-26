> Curated snapshot in FPGA-8-Bit-Computer, alongside [BE_8Bit_Computer](../BE_8Bit_Computer/) and [RAINCloud_SDRAM](../RAINCloud_SDRAM/).
> See [PUBLICATION.md](PUBLICATION.md) for source provenance, current checks and historical validation limits. The accelerator remains a proposal/software reference, not implemented hardware.

# RAINCloud Digital SAP

RAINCloud Digital | RAINCloud_SAP | J. Campbell

An FPGA version of J. Campbell's Ben Eater-inspired Simple As Possible
computer for the Terasic DE10-Lite (MAX 10, 10M50DAF484C7G).

[![RAINCloud Digital SAP system overview: clock, controller, 8-bit datapath, and diagnostic displays.](docs/images/sap-overview.png)](ARCHITECTURE.md)

Explore the [architecture and instruction walkthrough](ARCHITECTURE.md),
including the [detailed CPU datapath](ARCHITECTURE.md#datapath-and-bus-ownership)
and a source-linked map of all 21 modules.

Local branch exploration: [SAP and SDRAM matrix accelerator proposal](docs/AI_EDGE_ACCELERATOR.md).
This is architecture and a software reference; accelerator hardware is not yet implemented.

This project was created on 2026-10-15 from the active `BenEater_8Bit_Computer`
Quartus sources. It retains the structural registers, 74LS-style models,
8-bit datapath, 16-byte program/data RAM, instruction encoding, and display
selection interface. The clock/control path and arithmetic flag lifetime have
been revised. The original source files are preserved under `reference/original`.

**Historical status (2026-10-20): Quartus 25.1 compilation, fitted timing and all
five Questa functional suites were recorded passing. Board validation remains
pending.** See [VALIDATION.md](VALIDATION.md) for dated evidence and build warnings,
and [PUBLICATION.md](PUBLICATION.md) for the new checks on this copied snapshot.

## About RAINCloud Digital

RAINCloud Digital is a limited liability company helping bring ideas from
concept and prototype through product development and preparation for market.
Its services combine engineering, product development, intellectual-property
consulting, and marketing. This description draws on the company's
[mission](https://raincloud.digital/) and
[published services](https://raincloud.digital/terms-and-conditions).

RAINCloud_SAP is a RAINCloud Digital project documenting J. Campbell's SAP
computer design and FPGA implementation. Source headers use RAINCloud Digital
attribution and credit J. Campbell as the original author.

## Get the project

```powershell
git clone https://github.com/jerrycampbellus/FPGA-8-Bit-Computer.git
cd FPGA-8-Bit-Computer/RAINCloud_SAP
```

The active project is self-contained. The `reference/original` directory is a
historical snapshot, not a build input. No OneDrive checkout is required.

Requirements for the verified Windows workflow:

- Terasic DE10-Lite for hardware execution.
- Quartus Prime Lite 25.1std.0 with MAX 10 device support.
- Questa Altera Starter 2025.2 with a valid simulator license.
- Python 3.10 or newer for the standard-library-only check and test scripts.

The runner also supports Icarus Verilog; the published functional results were
obtained with Questa. Build and test commands create local output under `build/`.

## Open and build

Open `RAINCloud_SAP.qpf` in Quartus Prime Lite 25.1std.0. All build inputs use
project-relative paths and an explicit source list. Build from the project root:

```powershell
.\scripts\build.ps1
```

Pass `-QuartusBin` to use another installed Quartus directory. A successful
compilation creates `build/quartus/RAINCloud_SAP.sof`. Building does not program
the board. Generated files are excluded from Git.

## Verification

```powershell
python scripts/check_project.py
python scripts/run_tests.py --simulator questa --bin C:\altera_lite\25.1std\questa_fse\win64
```

`run_tests.py` supports Questa and Icarus Verilog and exits unsuccessfully if compilation,
simulation, an assertion, a timeout, or an explicit PASS check fails. It runs
five testbenches covering the clock, input conditioning, arithmetic/flags,
output formatting, and CPU programs. For Icarus, omit `--simulator questa` and
set `--bin` to the Icarus executable directory. For a compile-only Questa check,
run `.\scripts\compile_questa.ps1`.

The installed Questa GUI launcher is
`C:\altera_lite\25.1std\questa_fse\win64\questasim.exe`; batch simulation uses
`vsim.exe` in that directory. A valid Starter license is required for simulation.
Set `SALT_LICENSE_SERVER` to its `.dat` file, or supply
`--license C:\path\to\renewed_license.dat` to the runner to set it for that run only.
Obtain/renew the free license through the
[Altera Self-Service Licensing Center](https://www.altera.com/sslc).
License files belong outside the repository.

After changing your license environment, restart already-open Questa or terminal
sessions, or use `--license` explicitly for a single run. The runner keeps its
logical library mapping and simulator settings under `build/questa`.

The verified baseline passes all five suites, including 131,072 arithmetic
cases, 1,024 output-format cases, and 11 CPU programs. Quartus completes with
zero errors and nine documented warnings; fitted timing passes. These results
establish simulation and implementation readiness; board testing is still pending.

## Board controls

| Control | Function |
| --- | --- |
| KEY0 | Reset; press to assert, release synchronously with the board clock |
| KEY1 | Manual microstep; press executes the datapath, release advances control |
| SW0 | 0 continuous, 1 manual |
| SW3:1 | 000–110: 1, 2, 4, 8, 16, 32, 64 Hz; 111: 25 MHz |
| SW7:4 | Display selection below |
| SW8 | Interpret the stored OUT byte as signed two's complement |
| SW9 | OUT magnitude: 1 shows two hexadecimal digits; 0 shows three decimal digits |
| LEDR0 | CPU clock phase |
| LEDR9 | Halted |
| LEDR8:1 | Selected diagnostic byte |

The 111 setting deliberately preserves the original source's 25 MHz fast mode;
the old comment describing 128 Hz did not match its implementation. KEY1 uses
5 ms debounce at 50 MHz. Complete a manual press/release before changing mode.
One instruction takes five complete microsteps; HLT stops after its fetch and
decode. An already-held key is not accepted as a new step on entering manual mode.

Display selectors: 0 blank, 1 A, 2 B, 3 ALU, 4 flags, 5 MAR, 6 RAM,
7 PC, 8 OUT, 9 sampled data bus, A control word, B instruction register.
The internal bus is zero when no source is selected. `Bus_Display_Register`
captures the bus on each CPU rising edge when enabled and captures zero when
disabled. `JC_Display` selects that stored sample or another diagnostic value
to drive the board displays.

In the C (OUT) view, hexadecimal uses HEX1:HEX0 and blanks HEX2; decimal uses
all three numeric positions, HEX2:HEX0, including leading zeros. For example,
unsigned 255 displays `C___FF` in hex and `C__255` in decimal (`_` is blank).
The C label and sign position stay fixed, and changing SW9 works while halted.

## Instruction set

Each instruction is one byte: upper nibble opcode, lower nibble address.

| Opcode | Mnemonic | Operation |
| --- | --- | --- |
| 0x0 | NOP | No operation |
| 0x1 | LDA address | A = RAM[address] |
| 0x2 | ADD address | A = A + RAM[address]; update carry and zero |
| 0x3 | SUB address | A = A - RAM[address]; update borrow and zero |
| 0x4 | OUT | Capture A in the output register |
| 0x5 | JMP address | PC = address |
| 0x6 | STA address | RAM[address] = A |
| 0x7 | JZ address | Jump when zero flag is set |
| 0x8 | JC address | Jump when carry/borrow flag is set |
| 0xF | HLT | Halt until reset |
| 0x9–0xE | Undefined | Halt on decode |

Flag bit 0 is zero; bit 1 is addition carry or subtraction borrow. Flags change
only at ADD/SUB writeback or reset. Other instructions, including branches,
preserve them. JZ/JC replace misleading BNZ/BNC comments in the old sources;
the branch-on-set encoding is retained. This is the source project's ISA,
which differs from some other Ben Eater instruction maps.

## Program and reset behavior

`programs/ram_init.hex` contains the original 16-byte up/down counting program.
Edit it and rebuild to change the power-up program. RAM is writable, so STA can
modify either data or instructions. Reset clears the architectural registers,
flags, control state, and HALT; it preserves RAM contents. The diagnostic
`Bus_Display_Register` has no reset input or RTL initializer; its first CPU
rising edge establishes the sample, and reset alone does not clear it.
Reconfigure the FPGA to reload the initial image. PC arithmetic wraps modulo 16
and ALU arithmetic wraps modulo 256.

## Project files

- `rtl/`: authoritative active Verilog. Do not regenerate it from old BDF files.
- `constraints/`: board pins and timing constraints.
- `programs/`: RAM image.
- `sim/`, `scripts/`: regression benches and build/check commands.
- `reference/`: original source snapshot and SHA-256 provenance manifest.
- `NET_NAMES.md`: signal naming conventions and a link to the full rename map.
- [ARCHITECTURE.md](ARCHITECTURE.md): system and datapath diagrams, module
  connections, display routes, and a five-step instruction walkthrough.
- `docs/images/`: scalable SVG diagrams and PNG previews generated by
  `scripts/draw_architecture.py`.
- `PROJECT_MANIFEST.md`, `DECISIONS.md`, `INTERFACES.md`, `VALIDATION.md`:
  engineering scope, decisions, interfaces, and evidence.

## Attribution and notices

RAINCloud_SAP is a RAINCloud Digital project. J. Campbell authored the original
SAP design and codebase, inspired by Ben Eater's educational 8-bit computer.
Thirteen imported Verilog files retain the Intel notices emitted by the original
Quartus export. Existing file-level notices are preserved; no repository-wide
open-source license has been selected. See [NOTICE.md](NOTICE.md) for attribution
and licensing status.

For proposed changes or reproducible issue reports, see
[CONTRIBUTING.md](CONTRIBUTING.md). Historical source provenance is described in
[reference/README.md](reference/README.md). Generated build databases, simulator
licenses, and local programmer configuration are excluded from publication.
