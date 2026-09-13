[CmdletBinding()]
param(
    [string]$GodotBinary
)

. (Join-Path $PSScriptRoot "..\phase0\common.ps1")

$godotExecutable = Resolve-AnarchyballGodot -GodotBinary $GodotBinary
$godotVersion = Assert-AnarchyballGodotVersion -GodotExecutable $godotExecutable
$projectRoot = Get-AnarchyballProjectRoot

Invoke-AnarchyballGodot `
    -GodotExecutable $godotExecutable `
    -Arguments @(
        "--headless",
        "--path", $projectRoot,
        "--script", "res://tools/phase6/validate_content.gd"
    ) `
    -Operation "Content batch validation"

Write-Output "CONTENT BATCH PASS: $godotVersion"
