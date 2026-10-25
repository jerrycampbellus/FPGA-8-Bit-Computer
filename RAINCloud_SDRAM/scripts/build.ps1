param([string]$Quartus='C:/intelFPGA_lite/23.1std', [switch]$Regenerate)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
Push-Location $repo
try {
    New-Item -ItemType Directory -Force build | Out-Null
    if($Regenerate -or !(Test-Path src/ip/jtag_bridge/synthesis/jtag_bridge.qip)) {
        & "$Quartus/quartus/sopc_builder/bin/qsys-script.exe" --script=scripts/create_jtag.tcl *> build/qsys-create.log
        if($LASTEXITCODE -ne 0) {throw 'JTAG system creation failed; see build/qsys-create.log'}
        & "$Quartus/quartus/sopc_builder/bin/qsys-generate.exe" src/ip/jtag_bridge.qsys --synthesis=VERILOG *> build/qsys-generate.log
        if($LASTEXITCODE -ne 0) {throw 'JTAG generation failed; see build/qsys-generate.log'}
    }
    Push-Location quartus_project
    try {
        & "$Quartus/quartus/bin64/quartus_sh.exe" --flow compile SDRAM_Test_Harness *> ../build/integrated-build.log
        if($LASTEXITCODE -ne 0) {throw 'Quartus compilation failed; see build/integrated-build.log'}
        & "$Quartus/quartus/bin64/quartus_sta.exe" -t ../scripts/timing_report.tcl *> ../build/timing-report.log
        if($LASTEXITCODE -ne 0) {throw 'Timing report failed'}
        if(Select-String -Path ../build/integrated-build.log -Pattern 'Timing requirements not met|not fully constrained' -Quiet) {
            throw 'Timing acceptance failed. Do not treat compilation alone as validation.'
        }
        # Keep the reviewed HDL diagnostics visible and prevent their return.
        # Other vendor/board warnings remain in the log for separate assessment.
        if(Select-String -Path ../build/integrated-build.log -Pattern 'Warning \((10036|10230|10762)\):.*(tester_regs|sdram_controller|jtag_bridge_master_(timing_adt|b2p_adapter))\.sv' -Quiet) {
            throw 'Targeted HDL warning returned; inspect build/integrated-build.log.'
        }
    } finally {Pop-Location}
    Write-Output 'Build and timing checks passed. SOF: quartus_project/output_files/SDRAM_Test_Harness.sof'
} finally {Pop-Location}
