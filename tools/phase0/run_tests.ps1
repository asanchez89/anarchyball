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
        "--script", "res://addons/gdUnit4/bin/GdUnitCmdTool.gd",
        "--ignoreHeadlessMode",
        "--add", "res://tests/unit",
        "--report-directory", "res://reports"
    ) `
    -Operation "GdUnit4 test suite"

Write-Output "TESTS PASS: $godotVersion"
