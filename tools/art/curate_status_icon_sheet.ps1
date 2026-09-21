param(
    [Parameter(Mandatory = $true)][string]$Source,
    [string]$Destination = "assets/art/ui/status_icons_16bit_v1.png"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$root = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$sourceImage = [Drawing.Bitmap]::new((Resolve-Path $Source).Path)
$destinationPath = Join-Path $root $Destination
$sheet = [Drawing.Bitmap]::new(192, 32, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($sheet)
$graphics.Clear([Drawing.Color]::Transparent)
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$cellWidth = [int]($sourceImage.Width / 6)

for ($cell = 0; $cell -lt 6; $cell++) {
    $minX = $sourceImage.Width; $minY = $sourceImage.Height; $maxX = -1; $maxY = -1
    $startX = $cell * $cellWidth
    $endX = if ($cell -eq 5) { $sourceImage.Width } else { ($cell + 1) * $cellWidth }
    for ($y = 0; $y -lt $sourceImage.Height; $y++) {
        for ($x = $startX; $x -lt $endX; $x++) {
            if ($sourceImage.GetPixel($x, $y).A -gt 12) {
                $minX = [math]::Min($minX, $x); $maxX = [math]::Max($maxX, $x)
                $minY = [math]::Min($minY, $y); $maxY = [math]::Max($maxY, $y)
            }
        }
    }
    if ($maxX -lt $minX) { continue }
    $sourceRect = [Drawing.Rectangle]::new($minX, $minY, $maxX - $minX + 1, $maxY - $minY + 1)
    $scale = [math]::Min(28.0 / $sourceRect.Width, 28.0 / $sourceRect.Height)
    $width = [math]::Max(1, [int]($sourceRect.Width * $scale))
    $height = [math]::Max(1, [int]($sourceRect.Height * $scale))
    $targetRect = [Drawing.Rectangle]::new($cell * 32 + [int]((32 - $width) / 2), [int]((32 - $height) / 2), $width, $height)
    $graphics.DrawImage($sourceImage, $targetRect, $sourceRect, [Drawing.GraphicsUnit]::Pixel)
}

$directory = Split-Path $destinationPath
New-Item -ItemType Directory -Force -Path $directory | Out-Null
$sheet.Save($destinationPath, [Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose(); $sheet.Dispose(); $sourceImage.Dispose()
