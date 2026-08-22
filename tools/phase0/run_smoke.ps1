[CmdletBinding()]
param(
    [string]$GodotBinary
)

. (Join-Path $PSScriptRoot "common.ps1")

$godotExecutable = Resolve-AnarchyballGodot -GodotBinary $GodotBinary
$godotVersion = Assert-AnarchyballGodotVersion -GodotExecutable $godotExecutable
$projectRoot = Get-AnarchyballProjectRoot

Invoke-AnarchyballGodot `
    -GodotExecutable $godotExecutable `
    -Arguments @(
        "--headless",
        "--path", $projectRoot,
        "--script", "res://tests/smoke/bootstrap_smoke.gd"
    ) `
    -Operation "Bootstrap smoke test"

Write-Output "SMOKE PASS: $godotVersion"
