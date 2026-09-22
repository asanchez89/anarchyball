# Deterministic trim/fades of the licensed SciFi pack; no synthesis/model use.
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$source = Join-Path $projectRoot 'assets/sounds/SciFi-SoundDesignPack/SciFi-SoundDesignPack/SpaceShips/SciFi-V1_SpaceShips_18-FlyBy14_24b-48k.wav'
$bytes = [IO.File]::ReadAllBytes($source)
$channels = 0
$sampleRate = 0
$bits = 0
$dataStart = 0
$dataLength = 0
for ($offset = 12; $offset + 8 -le $bytes.Length;) {
    $tag = [Text.Encoding]::ASCII.GetString($bytes, $offset, 4)
    $length = [BitConverter]::ToInt32($bytes, $offset + 4)
    if ($tag -eq 'fmt ') {
        $format = [BitConverter]::ToUInt16($bytes, $offset + 8)
        if ($format -ne 1) { throw 'Expected PCM source.' }
        $channels = [BitConverter]::ToUInt16($bytes, $offset + 10)
        $sampleRate = [BitConverter]::ToInt32($bytes, $offset + 12)
        $bits = [BitConverter]::ToUInt16($bytes, $offset + 22)
    }
    if ($tag -eq 'data') { $dataStart = $offset + 8; $dataLength = $length }
    $offset += 8 + $length + ($length % 2)
}
if ($bits -ne 24 -or $channels -lt 1 -or $dataStart -eq 0) { throw 'Expected 24-bit PCM.' }
$frames = [int]($dataLength / (3 * $channels))
$samples = [double[]]::new($frames)
$peak = 0.0
$peakFrame = 0
for ($i = 0; $i -lt $frames; $i++) {
    $sum = 0.0
    for ($channel = 0; $channel -lt $channels; $channel++) {
        $index = $dataStart + ($i * $channels + $channel) * 3
        $value = [int]$bytes[$index] + ([int]$bytes[$index + 1] -shl 8) + ([int]$bytes[$index + 2] -shl 16)
        if ($value -ge 8388608) { $value -= 16777216 }
        $sum += $value / 8388608.0
    }
    $samples[$i] = $sum / $channels
    if ([math]::Abs($samples[$i]) -gt $peak) { $peak = [math]::Abs($samples[$i]); $peakFrame = $i }
}
if ($peak -le 0.0) { throw 'Silent source.' }
$count = [int]($sampleRate * 0.32)
$start = [math]::Clamp($peakFrame - [int]($count * 0.35), 0, $frames - $count)
$destination = Join-Path $projectRoot 'assets/audio/sfx/world_0/tactical_dash.wav'
$writer = [IO.BinaryWriter]::new([IO.File]::Create($destination))
try {
    $writer.Write([Text.Encoding]::ASCII.GetBytes('RIFF')); $writer.Write([int](36 + $count * 2))
    $writer.Write([Text.Encoding]::ASCII.GetBytes('WAVEfmt ')); $writer.Write([int]16)
    $writer.Write([int16]1); $writer.Write([int16]1); $writer.Write([int]$sampleRate)
    $writer.Write([int]($sampleRate * 2)); $writer.Write([int16]2); $writer.Write([int16]16)
    $writer.Write([Text.Encoding]::ASCII.GetBytes('data')); $writer.Write([int]($count * 2))
    for ($i = 0; $i -lt $count; $i++) {
        $fade = [math]::Min(1.0, $i / ($sampleRate * 0.018)) * [math]::Min(1.0, ($count - 1 - $i) / ($sampleRate * 0.1))
        $writer.Write([int16]($samples[$start + $i] / $peak * 24000.0 * $fade))
    }
} finally { $writer.Dispose() }
Write-Output "Prepared tactical_dash.wav: 0.32 s, mono, faded."
