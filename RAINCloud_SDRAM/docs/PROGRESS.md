# Implementation checklist

- [x] Inspect independent working copy, preserve six MPF relocation edits and ignored waveform files.
- [x] Rebuild baseline and record negative slack; recheck expired Questa load license.
- [x] Add baseline scoreboard/timeout and independent executable library regression.
- [x] Extract buffered byte-addressed library with internal initialization/refresh.
- [x] Shared local/remote engine, ownership, controlled stop, full failure display pages.
- [x] Patterns, ranges, repeats, masks, stalls, gaps, 64-bit metrics, bounded error log.
- [x] Generate installed Intel JTAG bridge; implement register contract, Tcl and Python API/CLI.
- [x] Replaceable Python transport and mock; specify future framed serial backend.
- [x] Final static timing and connected-board acceptance evidence, including user-confirmed physical controls/displays.
- [x] Package build/test commands and final validation record in [VALIDATION.md](VALIDATION.md).
- [x] Document optional CPU/cache and DMA/tile clients without building either application.

Preserved historical sources are a baseline, not a second supported controller.
The initial BL1 build is preserved in VALIDATION_BL1.md. The current build adds:

- [x] One 1..1024-word request with synchronous full-page buffers.
- [x] Real sequential SDRAM bursts, explicit termination, row splitting and refresh admission.
- [x] API 1.1 page staging window and legacy 16-word alias.
- [x] Capability-aware Python word/page API and binary-file CLI.
- [x] Full-page simulation, continuous data, masks, adjacent guards and stop checks.
- [x] Timing closure and programmed-board page/full-memory acceptance.

Controller 1.2 / build 26101403:

- [x] Named mode fields with one CAS source for chip programming and capture timing.
- [x] Elaboration rejection of unsupported parameter ranges; CL2/CL3 model coverage.
- [x] Application address/count/mask contract, including Python per-word byte masks.
- [x] Cycle profiling and reproducible hardware request-size benchmark.
- [x] Final 26101403 build, timing and hardware acceptance recorded.
- [x] RAINCloud code/testbench comments, testbench guide and comment-only verification.

Controller 1.2.1 / build 26101404:

- [x] Explicit arithmetic widths and bounded case selectors without address aliases.
- [x] Repeatable generated-JTAG adapter cleanup with generator-shape checks.
- [x] Added register/pattern edge cases and raw/prepared adapter port comparison.
- [x] Regenerated build, warning audit, timing and connected-board acceptance recorded.
