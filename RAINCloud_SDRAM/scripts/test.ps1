<#
.SYNOPSIS
Run the RAINCloud 26101404 / controller 1.2.1 simulation and host regression.
.DESCRIPTION
Builds five RTL runs (controller CL3/CL2, tester, board, performance), rejects
eight invalid parameter profiles, and runs Python unittest discovery. Uses the
ISSI model and behavioral board stubs, so neither Quartus nor a board is needed.
Build products and logs go to build/. See docs/TESTBENCH.md for coverage/debug.
.PARAMETER Python
Python 3.10+ executable or absolute path. The WindowsApps alias may not launch.
.PARAMETER Icarus
Directory containing iverilog.exe and vvp.exe. Defaults to the local bootstrap
installation, then PATH. That directory is also prepended to PATH for its DLLs.
.PARAMETER CompileOnly
Skip vvp execution only. Positive/negative elaboration and Python tests still run.
#>
param([string]$Python='python', [string]$Icarus='', [switch]$CompileOnly)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
Push-Location $repo
try {
    New-Item -ItemType Directory -Force build | Out-Null
    if(!$Icarus) {
        $local=Join-Path $repo 'build/tools/ucrt64/bin'
        $Icarus=if(Test-Path "$local/iverilog.exe") {$local} else {Split-Path (Get-Command iverilog -ErrorAction Stop).Source}
    }
    $env:PATH="$Icarus;"+$env:PATH
    foreach($test in @('controller','controller_cl2','tester','board','performance')) {
        # Both CAS profiles use the same source/test sequence and independent
        # expected MODE values. CL2 simulation does not qualify a CL2 board build.
        $top=if($test -eq 'controller_cl2') {'controller'} else {$test}
        $options=if($test -eq 'controller_cl2') {@('-P','tb_controller.TEST_CAS=2')} else {@()}
        $sources=@('rtl/library/sdram_controller.sv','rtl/tester/tester_regs.sv',"tests/tb_$top.sv",'src/rtl/IS42S16320F.v')
        if($test -eq 'board') {$sources+='rtl/board/sdram_tester_top.sv'}
        & "$Icarus/iverilog.exe" -g2012 -s "tb_$top" @options -o "build/$test.vvp" @sources
        if($LASTEXITCODE -ne 0) {throw "$test compilation failed"}
        if(!$CompileOnly) {
            # A zero exit code alone is insufficient: model diagnostics can be
            # printed without aborting. Require PASS and reject error text too.
            & "$Icarus/vvp.exe" "build/$test.vvp" *> "build/$test.log"
            if($LASTEXITCODE -ne 0) {Get-Content "build/$test.log" -Tail 12; throw "$test failed"}
            if(Get-Content "build/$test.log" | Where-Object {$_ -notmatch '^PASS ' -and $_ -match 'ERROR|VIOLATION|FATAL'}) {throw "$test model reported an error"}
            if(!(Select-String -Path "build/$test.log" -Pattern "PASS $top" -Quiet)) {throw "$test missing PASS marker"}
            Select-String -Path "build/$test.log" -Pattern "PASS $top" | ForEach-Object {$_.Line}
        }
    }
    foreach($profile in @('CAS=1','CAS=4','MAX_WORDS=0','MAX_WORDS=1025','TMRD=1','TRP=0','REFRESH_CYCLES=280','REFRESH_CYCLES=65536')) {
        # Compilation must fail for the intended configuration guard, not for
        # an unrelated missing tool/source. This log is overwritten per profile.
        & "$Icarus/iverilog.exe" -g2012 -s sdram_controller -P "sdram_controller.$profile" -o build/invalid.vvp rtl/library/sdram_controller.sv *> build/invalid-profile.log
        if($LASTEXITCODE -eq 0) {throw "Invalid profile accepted: $profile"}
        if(!(Select-String -Path build/invalid-profile.log -Pattern 'SDRAM_CONFIG_ERROR' -Quiet)) {throw "Unexpected failure for $profile"}
        Write-Output "PASS rejected unsupported profile $profile"
    }
    $env:PYTHONPATH=Join-Path $repo host
    & $Python -m unittest discover -s tests -v
    if($LASTEXITCODE -ne 0) {throw 'Host tests failed'}
} finally {Pop-Location}
