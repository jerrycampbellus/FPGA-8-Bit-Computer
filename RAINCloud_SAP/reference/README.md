# Original source and migration records

RAINCloud Digital | RAINCloud_SAP | J. Campbell

`original/` preserves 23 files imported from J. Campbell's
`BenEater_8Bit_Computer` project on 2026-10-15: 20 Verilog sources, the Quartus
settings and timing files, and the original RAM image. These files are retained
for provenance and comparison. The active build uses `../rtl/`, `../constraints/`,
and `../programs/` instead.

`SOURCE_MANIFEST.json` records the original project-relative source path,
snapshot path, and SHA-256 of each file. The `source` fields are rooted at
`BenEater_8Bit_Computer/`; a particular user's home directory is not required.
Run `python scripts/check_project.py` from the repository root to verify the
snapshot hashes along with the active source and board mapping checks.

The snapshot retains original contents, including historical absolute paths,
generated signal names, tool-export metadata, and vendor notices. Git attributes
disable line-ending conversion in this directory to preserve the file hashes.
Do not regenerate or edit these files as part of active development.

`NET_RENAMES.json` separately records the 190 descriptive identifier changes
made to the active RTL. NET_NAMES.md in the repository root explains the naming
conventions and examples. See NOTICE.md for attribution and licensing status.
