# Publication snapshot — 2026-10-25 UTC

Source: local `SDRAM_Tester_Working`, branch `work/sdram-tester`, commit
`ac7c35debd8dd37b5bf392cfd43dfea5f934c3c2` (Record SDRAM controller 1.2.1,
tester and host API milestone). This curated source copy is published at the
owner's request. It does not publish the source repository's Git history.

The live source-origin main was `541e2060d1951730f40c3256c5765d9c87b29737`;
the local branch was 3 commits ahead and 7 behind that older history. No merge,
reset, rebase or push to the source repository was performed. The current active
`rtl/`, host API and release records in the working milestone were selected, not
the older controller/AXI experiments or local Questa metadata edits.

97 committed files are included. [SOURCE_PROVENANCE.json](SOURCE_PROVENANCE.json)
records per-file source/publication SHA-256 values and 92 omitted tracked paths.
Only the README and two documentation portability/legacy-scope passages differ
from those source bytes. HDL, constraints, active project settings, host code,
tests, scripts, Qsys description, model and license are byte-identical to the
commit. No design changes are part of this publication.

## Checks executed on this copy

| Check | Result |
| --- | --- |
| Python host/mock regression | PASS: all 26 tests, Python standard-library unittest. |
| README mock page example | PASS: 2 KiB page write/read in mock memory only. |
| PowerShell full RTL/negative-profile runner | BLOCKED before execution by this machine's script-execution policy. No policy changes or bypass; no fresh RTL pass claimed. |
| Source equality, path/link and credential-pattern checks | PASS for the curated source/document set; generated outputs excluded. |
| Quartus build, IP generation, adapter comparison, fitted timing | NOT RUN for this publication. |
| Board programming / physical measurements | NOT RUN. |

The blocked runner does not demonstrate a circuit/test failure. The retained
October 14 records report five RTL runs, eight invalid-profile rejections,
26 host tests and specific fitted/board results for historical release builds.
Those are historical evidence, not reruns. They do not qualify arbitrary
parameter/board changes, CAS=2 hardware, GPIO use, or integration into SAP.
Saved release hashes are preserved as recorded; use the publication manifest
for the exact committed bytes supplied here, including Git newline conventions.

## Curation and licensing

The active controller/tester/top, host transport, tests, timing/pin constraints,
build scripts and Qsys source are included. The only retained `src/rtl/` file is
the RAINCloud behavioral IS42S16320F model used by the tests. It is not a vendor
qualification guarantee. Source notices credit J. Campbell/RAINCloud and MIT.

Excluded: old Questa projects and relocation edits; legacy controller/top/test
sources; obsolete generated IP; vendor PDF copies; tool caches/databases,
waveforms, bitstreams and nested Git data. Small intentionally versioned
validation records remain under docs/ as dated evidence. Historical references
to omitted legacy artifacts do not make them active build dependencies.
The testbench guide uses a generic Python executable instead of a personal path.

The [MIT license](LICENSE) and existing file-level notices are preserved.
Terasic pin assignments and Intel tool dependencies remain identified. Generated
Intel IP must be obtained through licensed vendor tools under applicable terms;
no tool installers, runtime libraries or license files are included. The MIT
license applies to this source scope, not neighboring SAP/BE material.
