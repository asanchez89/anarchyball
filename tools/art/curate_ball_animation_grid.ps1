param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$root = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$sourceImage = [Drawing.Bitmap]::new((Resolve-Path $Source).Path)
$destinationPath = Join-Path $root $Destination
$sheet = [Drawing.Bitmap]::new(768, 768, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($sheet)
$graphics.Clear([Drawing.Color]::Transparent)
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half

for ($row = 0; $row -lt 8; $row++) {
    for ($column = 0; $column -lt 8; $column++) {
        $left = [int][math]::Round($column * $sourceImage.Width / 8.0)
        $top = [int][math]::Round($row * $sourceImage.Height / 8.0)
        $right = [int][math]::Round(($column + 1) * $sourceImage.Width / 8.0)
        $bottom = [int][math]::Round(($row + 1) * $sourceImage.Height / 8.0)
        $sourceRect = [Drawing.Rectangle]::new($left, $top, $right - $left, $bottom - $top)
        $targetRect = [Drawing.Rectangle]::new($column * 96 + 7, $row * 96 + 7, 82, 82)
        $graphics.DrawImage($sourceImage, $targetRect, $sourceRect, [Drawing.GraphicsUnit]::Pixel)
    }
}

New-Item -ItemType Directory -Force -Path (Split-Path $destinationPath) | Out-Null
$sheet.Save($destinationPath, [Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose(); $sheet.Dispose(); $sourceImage.Dispose()
