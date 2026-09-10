[CmdletBinding()]
param(
    [string]$GodotBinary,
    [string]$OutputPath
)

. (Join-Path $PSScriptRoot "..\phase0\common.ps1")

$godotExecutable = Resolve-AnarchyballGodot -GodotBinary $GodotBinary
$godotVersion = Assert-AnarchyballGodotVersion -GodotExecutable $godotExecutable
$projectRoot = Get-AnarchyballProjectRoot
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectRoot "builds\windows\anarchyball.exe"
}
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
$buildRoot = [System.IO.Path]::GetFullPath((Join-Path $projectRoot "builds"))
if (-not $resolvedOutput.StartsWith($buildRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputPath must stay inside $buildRoot"
}
$outputDirectory = Split-Path -Parent $resolvedOutput
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

Invoke-AnarchyballGodot `
    -GodotExecutable $godotExecutable `
    -Arguments @("--headless", "--path", $projectRoot, "--export-release", "Windows Desktop", $resolvedOutput) `
    -Operation "Windows release export"

if (-not (Test-Path -LiteralPath $resolvedOutput -PathType Leaf)) {
    throw "Godot reported success but did not create $resolvedOutput"
}
$pckPath = [System.IO.Path]::ChangeExtension($resolvedOutput, ".pck")
if (-not (Test-Path -LiteralPath $pckPath -PathType Leaf)) {
    throw "Expected sidecar package was not created: $pckPath"
}
Write-Output "WINDOWS BUILD PASS: $godotVersion -> $resolvedOutput"
