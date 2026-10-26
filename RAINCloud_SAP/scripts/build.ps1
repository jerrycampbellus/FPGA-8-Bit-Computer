# RAINCloud Digital | RAINCloud_SAP
# Original SAP design and codebase: J. Campbell.
#
param([string]$QuartusBin = 'C:\altera_lite\25.1std\quartus\bin64')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    New-Item -ItemType Directory -Path 'build' -Force | Out-Null
    & (Join-Path $QuartusBin 'quartus_sh.exe') --flow compile RAINCloud_SAP 2>&1 |
        Tee-Object -FilePath 'build/compile.log'
    if ($LASTEXITCODE -ne 0) { throw "Quartus compilation failed ($LASTEXITCODE)" }
} finally { Pop-Location }
