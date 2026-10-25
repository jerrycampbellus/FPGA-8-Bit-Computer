# Optional generated-IP checks, after a full build or prepare_jtag.tcl.
# The portable regression in test.ps1 intentionally does not require generated IP.
param([string]$Quartus='C:/intelFPGA_lite/23.1std', [string]$Icarus='')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
Push-Location $repo
try {
    New-Item -ItemType Directory -Force build/jtag-check | Out-Null
    & "$Quartus/quartus/bin64/quartus_sh.exe" -t tests/test_prepare_jtag.tcl *> build/jtag-check/prepare-tests.log
    if($LASTEXITCODE -ne 0) {throw 'Adapter preparation checks failed; see build/jtag-check/prepare-tests.log'}
    if(!$Icarus) {
        $local=Join-Path $repo 'build/tools/ucrt64/bin'
        $Icarus=if(Test-Path "$local/iverilog.exe") {$local} else {Split-Path (Get-Command iverilog -ErrorAction Stop).Source}
    }
    $env:PATH="$Icarus;"+$env:PATH
    $sources=@('tests/tb_jtag_adapters.sv')
    foreach($name in @('jtag_bridge_master_timing_adt','jtag_bridge_master_b2p_adapter')) {
        $raw=Get-Content "build/jtag-raw/$name.sv" -Raw
        $pattern="module $name\b"
        if([regex]::Matches($raw,$pattern).Count -ne 1) {throw "Unexpected raw module: $name"}
        [regex]::Replace($raw,$pattern,"module ${name}_original") | Set-Content "build/jtag-check/${name}_original.sv"
        $sources+="build/jtag-check/${name}_original.sv"
        $sources+="src/ip/jtag_bridge/synthesis/submodules/$name.sv"
    }
    & "$Icarus/iverilog.exe" -g2012 -s tb_jtag_adapters -o build/jtag-check/adapters.vvp @sources
    if($LASTEXITCODE -ne 0) {throw 'Adapter comparison compilation failed'}
    & "$Icarus/vvp.exe" build/jtag-check/adapters.vvp *> build/jtag-check/adapters.log
    if($LASTEXITCODE -ne 0 -or !(Select-String -Path build/jtag-check/adapters.log -Pattern '^PASS jtag_adapters:' -Quiet)) {
        throw 'Adapter port-equivalence check failed; see build/jtag-check/adapters.log'
    }
    Select-String -Path build/jtag-check/prepare-tests.log,build/jtag-check/adapters.log -Pattern '^PASS' | ForEach-Object {$_.Line}
} finally {Pop-Location}
