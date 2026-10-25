# Contributing and reporting issues

RAINCloud Digital | RAINCloud_SAP | J. Campbell

This project preserves J. Campbell's structural SAP computer design for the
DE10-Lite. Read README.md, INTERFACES.md, and NOTICE.md before proposing changes.

## Report a problem

Use the repository's GitHub Issues page. Include the commit being tested,
Quartus/Questa versions, operating system, exact reproduction commands, and
relevant diagnostics. For hardware issues, also identify the DE10-Lite board
revision, program image, switch settings, and expected versus observed behavior.
Exclude license files, credentials, and machine identifiers from attachments.

## Prepare a change

1. Create a branch for a focused change.
2. Edit active files in `rtl/`, `constraints/`, `programs/`, `sim/`, or `scripts/`.
   Preserve the original snapshot under `reference/original/` and its hashes.
3. Use the internal naming conventions in NET_NAMES.md and retain source notices.
4. Add or update a regression when behavior changes. Keep `sim/sources.f` and
   the Quartus source list consistent if a design module is added or removed.
5. Update the relevant engineering records and CHANGELOG.md.

## Validate

From the project root, with Python and the tools installed:

```powershell
python scripts/check_project.py
python scripts/run_tests.py --simulator questa --bin C:\altera_lite\25.1std\questa_fse\win64
.\scripts\build.ps1
```

Adjust the tool paths for your installation. The test runner accepts
`--license` for a per-run Questa license path. `build.ps1` accepts `-QuartusBin`.
The README also describes the optional Icarus backend.

A pull request should explain the behavior changed, commands run, results,
and any validation that remains pending. A compiler-only check is not a
simulation pass. Compare Quartus diagnostics with the nine expected warnings
documented in VALIDATION.md, and investigate new warnings or timing failures.

Generated output under `build/`, tool databases, programming images, and local
programmer chains remain untracked. Hardware testing is recorded separately
from RTL simulation and fitted timing.
