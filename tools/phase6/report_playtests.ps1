[CmdletBinding()]
param(
    [string]$GodotBinary,
    [string]$LevelId = "occupancy_workshop_draft"
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
        "--script", "res://tools/phase6/report_playtests.gd",
        "--",
        "--level-id=$LevelId"
    ) `
    -Operation "Playtest report"

Write-Output "PLAYTEST REPORT PASS: $godotVersion"
