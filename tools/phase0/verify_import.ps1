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
    -Arguments @("--headless", "--path", $projectRoot, "--editor", "--quit") `
    -Operation "Headless import"

Write-Output "IMPORT PASS: $godotVersion"
