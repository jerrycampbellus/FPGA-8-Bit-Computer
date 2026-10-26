# Publication snapshot — 2026-10-25 UTC

Source: RAINCloud_SAP, branch `explore/ai-edge-accelerator`, commit
`9cdf1684809d64e1f6a46de408bbaf502685e898` (Record SDRAM matrix accelerator
proposal and software reference). This is one commit ahead of the live public
source `main` observed at `baf85d70b430fd8f4a274b24091195cb22c17570`.
The public source is https://github.com/jerrycampbellus/RAINCloud_SAP .

All 83 tracked source files were copied from the commit, including the 23-file
historical reference snapshot. The local uncommitted QSF formatting change was
not copied. Only README navigation, clone instructions and validation wording
were adapted. RTL, pins, timing constraints, programs, benches, scripts, notices
and reference bytes are unchanged. [SOURCE_PROVENANCE.json](SOURCE_PROVENANCE.json)
records both source and publication SHA-256 values.

## Checks executed on this copy

| Check | Result |
| --- | --- |
| Structural checker | PASS: 21 modules, 71 pins, 16 program bytes, all 23 reference hashes. |
| Matrix software reference self-test | PASS: 107 directed/seeded reference vectors; software only. |
| Questa Altera Starter 2025.2 | PASS: compile and all five functional suites; zero errors/warnings. |
| Icarus 13.0 | PARTIAL: clock, inputs and 131,072-case ALU suites pass. Output bench fails compilation because this engine does not support unpacked array parameters; CPU suite not reached. |
| Quartus implementation / fitted timing | NOT RUN for this publication. See dated source records. |
| Board programming / measurement | NOT RUN; hardware qualification remains pending. |

Questa coverage includes 1,024 output formats and 11 CPU programs in addition to
clock, input and arithmetic tests. The documented Questa runner was used without
source changes. Icarus's limitation is not an all-suite pass; prefer Questa for
the complete current suite. Logs remain in the isolated local publication audit;
tool runtime files and generated simulator databases are not published.

The source VALIDATION.md contains dated earlier builds and measurements. Its
October 15 accelerator dependency inspection predates later source commits; it
does not establish a newly integrated SAP+SDRAM system. The accelerator is a
proposal/software reference, with no implemented accelerator hardware here.

## Scope and licensing

J. Campbell's authorship and Ben Eater inspiration remain credited. No new license
grant is assigned: [NOTICE.md](NOTICE.md) retains SAP's unselected project-license
status and the imported Intel file-level terms. No vendor tool, runtime, license,
credential or generated bitstream is distributed. The original reference files
retain their already-public historical tool paths for hash-based provenance;
they are not active build inputs. Local source repository files and staging were
preserved. Neighboring BE files are unchanged.
