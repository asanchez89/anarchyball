param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination,
    [double]$Scale = 1.47,
    [double]$SourceBaseline = 80.0,
    [double]$TargetBaseline = 90.0
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$root = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$sourceImage = [Drawing.Bitmap]::new((Resolve-Path $Source).Path)
$sheet = [Drawing.Bitmap]::new(768, 768, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($sheet)
$graphics.Clear([Drawing.Color]::Transparent)
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$scaledCell = [int][math]::Round(96.0 * $Scale)
$targetOffsetX = [int][math]::Round(48.0 - 48.0 * $Scale)
$targetOffsetY = [int][math]::Round($TargetBaseline - $SourceBaseline * $Scale)

for ($row = 0; $row -lt 8; $row++) {
    for ($column = 0; $column -lt 8; $column++) {
        $state = $graphics.Save()
        $cellBounds = [Drawing.Rectangle]::new($column * 96, $row * 96, 96, 96)
        $graphics.SetClip($cellBounds)
        $sourceRect = [Drawing.Rectangle]::new($column * 96, $row * 96, 96, 96)
        $targetRect = [Drawing.Rectangle]::new($column * 96 + $targetOffsetX, $row * 96 + $targetOffsetY, $scaledCell, $scaledCell)
        $graphics.DrawImage($sourceImage, $targetRect, $sourceRect, [Drawing.GraphicsUnit]::Pixel)
        $graphics.Restore($state)
    }
}

$destinationPath = Join-Path $root $Destination
New-Item -ItemType Directory -Force -Path (Split-Path $destinationPath) | Out-Null
$sheet.Save($destinationPath, [Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose(); $sheet.Dispose(); $sourceImage.Dispose()
