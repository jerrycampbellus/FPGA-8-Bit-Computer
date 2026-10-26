# RAINCloud Digital | RAINCloud_SAP
# Original SAP design and codebase: J. Campbell.
#
param([string]$QuestaBin = 'C:\altera_lite\25.1std\questa_fse\win64')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    New-Item -ItemType Directory -Path 'build/questa' -Force | Out-Null
    if (!(Test-Path -LiteralPath 'build/questa/work')) {
        & (Join-Path $QuestaBin 'vlib.exe') build/questa/work
        if ($LASTEXITCODE -ne 0) { throw 'vlib failed' }
    }
    & (Join-Path $QuestaBin 'vlog.exe') -sv -timescale 1ns/1ps -work build/questa/work `
        -f sim/sources.f sim/tb_clock.sv sim/tb_inputs.sv sim/tb_alu.sv `
        sim/tb_output.sv sim/tb_cpu.sv 2>&1 | Tee-Object -FilePath 'build/questa/compile.log'
    if ($LASTEXITCODE -ne 0) { throw 'Questa compilation failed' }
    Write-Output 'Compile-only check passed. No functional simulation was run.'
} finally { Pop-Location }
