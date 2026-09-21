param([string]$OutputDirectory = "assets/audio/sfx/world_0/generated")

$ErrorActionPreference = "Stop"
$sampleRate = 22050
$root = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$output = Join-Path $root $OutputDirectory
New-Item -ItemType Directory -Force -Path $output | Out-Null

function Write-RetroCue([string]$Name, [array]$Notes) {
    $samples = [System.Collections.Generic.List[int16]]::new()
    foreach ($note in $Notes) {
        $count = [int]($sampleRate * [double]$note[1])
        for ($i = 0; $i -lt $count; $i++) {
            $phase = (($i * [double]$note[0] / $sampleRate) % 1.0)
            $envelope = [math]::Min(1.0, $i / ($sampleRate * 0.006)) * [math]::Min(1.0, ($count - $i) / ($sampleRate * 0.025))
            $wave = if ($phase -lt 0.5) { 1.0 } else { -1.0 }
            $samples.Add([int16]($wave * 7200.0 * $envelope))
        }
    }
    $path = Join-Path $output $Name
    $stream = [IO.File]::Create($path)
    $writer = [IO.BinaryWriter]::new($stream)
    $dataSize = $samples.Count * 2
    $writer.Write([Text.Encoding]::ASCII.GetBytes("RIFF")); $writer.Write(36 + $dataSize)
    $writer.Write([Text.Encoding]::ASCII.GetBytes("WAVEfmt ")); $writer.Write(16); $writer.Write([int16]1); $writer.Write([int16]1)
    $writer.Write($sampleRate); $writer.Write($sampleRate * 2); $writer.Write([int16]2); $writer.Write([int16]16)
    $writer.Write([Text.Encoding]::ASCII.GetBytes("data")); $writer.Write($dataSize)
    foreach ($sample in $samples) { $writer.Write($sample) }
    $writer.Dispose(); $stream.Dispose()
}

Write-RetroCue "pickup_retro.wav" @(@(784, .055), @(988, .055), @(1318, .11))
Write-RetroCue "machine_activate_retro.wav" @(@(196, .07), @(294, .07), @(440, .08), @(659, .14))
Write-RetroCue "checkpoint_retro.wav" @(@(523, .08), @(659, .08), @(784, .09), @(1047, .16))
Write-RetroCue "threat_retro.wav" @(@(740, .075), @(1, .025), @(740, .075))
Write-RetroCue "aggression_retro.wav" @(@(330, .065), @(247, .065), @(165, .14))
Write-RetroCue "surrender_retro.wav" @(@(392, .07), @(523, .07), @(659, .14))
