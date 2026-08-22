Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:RequiredGodotVersion = "4.6.3.stable"


function Resolve-AnarchyballGodot {
    [CmdletBinding()]
    param(
        [string]$GodotBinary
    )

    $candidate = $GodotBinary
    if ([string]::IsNullOrWhiteSpace($candidate)) {
        $candidate = $env:GODOT_BIN
    }

    if ([string]::IsNullOrWhiteSpace($candidate)) {
        $command = Get-Command godot, godot4, godot_console -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($null -ne $command) {
            $candidate = $command.Source
        }
    }

    if ([string]::IsNullOrWhiteSpace($candidate)) {
        throw "Godot was not found. Pass -GodotBinary or set GODOT_BIN."
    }

    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        throw "Godot binary does not exist: $candidate"
    }

    return (Resolve-Path -LiteralPath $candidate).Path
}


function Assert-AnarchyballGodotVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GodotExecutable
    )

    $versionLines = & $GodotExecutable --version
    if ($LASTEXITCODE -ne 0) {
        throw "Godot --version failed with exit code $LASTEXITCODE."
    }

    $versionOutput = $versionLines | Select-Object -First 1
    $version = $versionOutput.Trim()
    if (-not $version.StartsWith($script:RequiredGodotVersion)) {
        throw "Expected Godot $($script:RequiredGodotVersion), found $version."
    }

    return $version
}


function Invoke-AnarchyballGodot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GodotExecutable,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$Operation
    )

    & $GodotExecutable @Arguments
    $operationExitCode = $LASTEXITCODE
    if ($operationExitCode -ne 0) {
        throw "$Operation failed with exit code $operationExitCode."
    }
}


function Get-AnarchyballProjectRoot {
    $toolsRoot = Join-Path $PSScriptRoot ".."
    return (Resolve-Path -LiteralPath (Join-Path $toolsRoot "..")).Path
}
