# Architecture graphics

RAINCloud Digital | RAINCloud_SAP | J. Campbell

| Asset | Purpose | Native size |
| --- | --- | --- |
| [sap-overview.svg](sap-overview.svg) / [PNG](sap-overview.png) | GitHub README summary and system overview | 1440 × 960 |
| [sap-datapath.svg](sap-datapath.svg) / [PNG](sap-datapath.png) | CPU module connections and shared-bus data routes | 1500 × 1030 |

The editable source is [draw_architecture.py](../../scripts/draw_architecture.py).
The diagrams use vector shapes and text without external images, fonts, or
scripts. Explanations and the complete module map are in
[ARCHITECTURE.md](../../ARCHITECTURE.md).

Run `python scripts/draw_architecture.py` from the project root to regenerate
the SVGs. Export PNGs at the native SVG dimensions using an SVG renderer. The
checked-in previews were rendered with Node.js and the `sharp` package; with
that optional package available, the equivalent project-root command is:

```powershell
node -e "const sharp = require('sharp'); (async () => { for (const n of ['sap-overview', 'sap-datapath']) { await sharp('docs/images/' + n + '.svg').png().toFile('docs/images/' + n + '.png'); } })().catch(e => { console.error(e); process.exit(1); });"
```

Node.js and `sharp` are only needed for this export method; they are not FPGA
build or simulation dependencies. Inspect both rendered PNGs after changes,
and commit each PNG with its matching SVG and generator.
