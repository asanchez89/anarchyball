[CmdletBinding()]
param(
    [string]$GodotBinary
)

$verificationScripts = @(
    "verify_import.ps1",
    "run_smoke.ps1",
    "run_tests.ps1"
)

foreach ($verificationScript in $verificationScripts) {
    $scriptPath = Join-Path $PSScriptRoot $verificationScript
    & $scriptPath -GodotBinary $GodotBinary
}

Write-Output "VERIFY ALL PASS"
