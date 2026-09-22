param([string]$OutputDirectory = "assets/audio/sfx/world_0/generated", [switch]$TheftOnly)

$ErrorActionPreference = "Stop"
$sampleRate = 22050
$root = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$output = Join-Path $root $OutputDirectory
New-Item -ItemType Directory -Force -Path $output | Out-Null

function Write-RetroCue([string]$Name, [array]$Notes, [double]$Gain = 7200.0, [double]$HarmonicRatio = 0.0) {
    $samples = [System.Collections.Generic.List[int16]]::new()
    foreach ($note in $Notes) {
        $count = [int]($sampleRate * [double]$note[1])
        $phaseAccumulator = 0.0
        for ($i = 0; $i -lt $count; $i++) {
            $frequency = [double]$note[0]
            if ($note.Count -gt 2) {
                $frequency += ([double]$note[2] - $frequency) * $i / $count
            }
            $phase = if ($note.Count -gt 2) { $phaseAccumulator % 1.0 } else { (($i * $frequency / $sampleRate) % 1.0) }
            $phaseAccumulator += $frequency / $sampleRate
            $envelope = [math]::Min(1.0, $i / ($sampleRate * 0.006)) * [math]::Min(1.0, ($count - $i) / ($sampleRate * 0.025))
            $wave = if ($phase -lt 0.5) { 1.0 } else { -1.0 }
            if ($HarmonicRatio -gt 0.0) {
                $overtone = [math]::Sin(2.0 * [math]::PI * $phaseAccumulator * $HarmonicRatio)
                $wave = 0.7 * $wave + 0.3 * $overtone
            }
            $samples.Add([int16]($wave * $Gain * $envelope))
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

Write-RetroCue "theft_retro.wav" @(@(1397, .065, 988), @(784, .065, 523), @(392, .13, 262)) 10000.0 2.0
Write-RetroCue "contact_hit_retro.wav" @(@(160, .055, 70), @(70, .065, 35)) 10000.0
if ($TheftOnly) { return }

Write-RetroCue "pickup_retro.wav" @(@(784, .055), @(988, .055), @(1318, .11))
Write-RetroCue "machine_activate_retro.wav" @(@(196, .07), @(294, .07), @(440, .08), @(659, .14))
Write-RetroCue "checkpoint_retro.wav" @(@(523, .08), @(659, .08), @(784, .09), @(1047, .16))
Write-RetroCue "threat_retro.wav" @(@(740, .075), @(1, .025), @(740, .075))
Write-RetroCue "aggression_retro.wav" @(@(330, .065), @(247, .065), @(165, .14))
Write-RetroCue "surrender_retro.wav" @(@(392, .07), @(523, .07), @(659, .14))
Write-RetroCue "dispute_retro.wav" @(@(440, .07), @(466, .09))
Write-RetroCue "alert_clear_retro.wav" @(@(659, .075), @(523, .075), @(392, .12))
Write-RetroCue "neutralized_retro.wav" @(@(330, .065), @(440, .065), @(554, .12))
Write-RetroCue "gate_open_retro.wav" @(@(196, .06), @(392, .06), @(587, .075), @(784, .075), @(988, .16))
Write-RetroCue "detection_alert_retro.wav" @(@(920, .028, 1800), @(1568, .095, 1480), @(1175, .20, 1046)) 12000.0 1.4983
