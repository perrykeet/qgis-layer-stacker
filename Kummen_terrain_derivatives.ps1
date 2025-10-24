# Kummen_terrain_derivatives.ps1
# PowerShell script to check DSM and generate terrain derivatives (slope, aspect, hillshade, color-relief)
# for the Kummen test area (map created 20250618).
# Outputs are written to the same input_layers folder.
#
# Requirements:
# - GDAL (gdalinfo, gdalwarp, gdaldem) must be in your PATH (run from OSGeo4W shell or a PowerShell with GDAL set up)
# - Run this script from PowerShell or the OSGeo4W PowerShell environment
#
# Author: ChatGPT
# Date: 2025-10-23

# -----------------------------
# User-editable variables
# -----------------------------

$baseFolder = 'C:\Users\lnper\Desktop\AlpineBirdProject\Classification Tests\Kummen\Supervised\input_layers'
$dsmName = 'Kummen20250618_dsm.tif'
$testOrthoName = 'KU-Kummen20250618.tif'
$thermalName = 'KU-Kummen20250618-thermal-orthophoto.tif'  # change extension if different

# target pixel size: use your test orthophoto pixel size (meters)
$targetResolution = 0.03999

# Vertical exaggeration for hillshade (use 1 unless DSM vertical units differ)
$verticalExaggeration = 1

# Azimuth and altitude for hillshade
$hill_az = 315
$hill_alt = 45

# -----------------------------
# Derived output names
# -----------------------------
$dsmPath = Join-Path $baseFolder $dsmName
$dsmResampled = Join-Path $baseFolder ([io.path]::GetFileNameWithoutExtension($dsmName) + '_resampled.tif')
$slopePath = Join-Path $baseFolder ([io.path]::GetFileNameWithoutExtension($dsmName) + '_slope.tif')
$aspectPath = Join-Path $baseFolder ([io.path]::GetFileNameWithoutExtension($dsmName) + '_aspect.tif')
$hillshadePath = Join-Path $baseFolder ([io.path]::GetFileNameWithoutExtension($dsmName) + '_hillshade.tif')
$colorTxt = Join-Path $baseFolder 'dsm_color.txt'
$colorReliefPath = Join-Path $baseFolder ([io.path]::GetFileNameWithoutExtension($dsmName) + '_color_relief.tif')

# Optional thermal resample outputs
$thermalPath = Join-Path $baseFolder $thermalName
$thermalResampled = Join-Path $baseFolder ([io.path]::GetFileNameWithoutExtension($thermalName) + '_resampled.tif')

# -----------------------------
# 1) Basic existence checks
# -----------------------------
Write-Host "Checking files..." -ForegroundColor Green
if (-not (Test-Path $dsmPath)) { throw "DSM not found: $dsmPath" }
if (-not (Test-Path (Join-Path $baseFolder $testOrthoName))) { Write-Warning "Test orthophoto not found: $testOrthoName (continuing; only DSM derivatives will be created)" }
if (-not (Test-Path $thermalPath)) { Write-Warning "Thermal orthophoto not found: $thermalName (resampling thermal is optional and will be skipped)" }

# -----------------------------
# 2) Inspect DSM with gdalinfo
# -----------------------------
Write-Host "Inspecting DSM with gdalinfo..." -ForegroundColor Green
& gdalinfo $dsmPath | Select-String "Size","Coordinate System is","Pixel Size","Upper Left","Lower Right","Band" | ForEach-Object { Write-Host $_.Line }

# -----------------------------
# 3) Resample DSM to target resolution (if needed)
# -----------------------------
Write-Host "Resampling DSM to target resolution $targetResolution m..." -ForegroundColor Green
& gdalwarp -tr $targetResolution $targetResolution -r bilinear -t_srs EPSG:32632 $dsmPath $dsmResampled
Write-Host "Resampled DSM -> $dsmResampled" -ForegroundColor Yellow

# -----------------------------
# 4) Generate slope
# -----------------------------
Write-Host "Generating slope..." -ForegroundColor Green
& gdaldem slope $dsmResampled $slopePath
Write-Host "Slope -> $slopePath" -ForegroundColor Yellow

# -----------------------------
# 5) Generate aspect
# -----------------------------
Write-Host "Generating aspect..." -ForegroundColor Green
& gdaldem aspect $dsmResampled $aspectPath
Write-Host "Aspect -> $aspectPath" -ForegroundColor Yellow

# -----------------------------
# 6) Generate hillshade
# -----------------------------
Write-Host "Generating hillshade (az=$hill_az alt=$hill_alt z=$verticalExaggeration)..." -ForegroundColor Green
& gdaldem hillshade -az $hill_az -alt $hill_alt -z $verticalExaggeration $dsmResampled $hillshadePath
Write-Host "Hillshade -> $hillshadePath" -ForegroundColor Yellow

# -----------------------------
# 7) Create a color-relief map for visual debugging
# -----------------------------
Write-Host "Creating color table for color-relief..." -ForegroundColor Green
$colorContent = @"
# elevation R G B
0 0 0 128
10 0 64 255
20 0 255 255
40 0 255 0
80 255 255 0
120 255 128 0
200 255 0 0
400 255 255 255
"@
Set-Content -Path $colorTxt -Value $colorContent -Encoding ASCII
Write-Host "Color table -> $colorTxt" -ForegroundColor Yellow

Write-Host "Generating color relief..." -ForegroundColor Green
& gdaldem color-relief $dsmResampled $colorTxt $colorReliefPath
Write-Host "Color relief -> $colorReliefPath" -ForegroundColor Yellow

# -----------------------------
# 8) Optional: resample thermal orthophoto
# -----------------------------
if (Test-Path $thermalPath) {
    Write-Host "Resampling thermal orthophoto to target resolution (optional)..." -ForegroundColor Green
    & gdalwarp -tr $targetResolution $targetResolution -r bilinear -t_srs EPSG:32632 $thermalPath $thermalResampled
    Write-Host "Thermal resampled -> $thermalResampled" -ForegroundColor Yellow
} else {
    Write-Host "Thermal file not present; skipping thermal resample." -ForegroundColor Cyan
}

# -----------------------------
# 9) Summary
# -----------------------------
Write-Host "`nAll derivative products created in: $baseFolder" -ForegroundColor Green
Write-Host "Files created:" -ForegroundColor Green
Get-ChildItem $baseFolder | Where-Object { $_.Name -match 'resampled|slope|aspect|hillshade|color_relief' } | ForEach-Object { Write-Host $_.Name }

# -----------------------------
# 10) NoData
# -----------------------------

Write-Host "Cleaning NoData values only for DSM-type rasters..."
$files = Get-ChildItem -Path $PSScriptRoot -Filter "Kummen20250618_dsm*.tif"

foreach ($f in $files) {
    if ($f.Name -match "slope|aspect|hillshade|color_relief") {
        Write-Host "Skipping NoData reset for $($f.Name) (values like 0 are valid)"
    } else {
        Write-Host "Applying NoData=0 to $($f.Name)"
        & gdal_translate -of GTiff -a_nodata 0 $f.FullName "$($f.DirectoryName)\tmp_$($f.Name)"
        Move-Item -Force "$($f.DirectoryName)\tmp_$($f.Name)" $f.FullName
    }
}
Write-Host "Done cleaning DSM rasters."

# -----------------------------
# 11) Create Overviews
# -----------------------------

Write-Host "Building overviews (pyramids) for faster QGIS display..."
$files = Get-ChildItem -Path $PSScriptRoot -Filter "*.tif"

foreach ($f in $files) {
    Write-Host "Creating overviews for $($f.Name)..."
    & gdaladdo -r average $f.FullName 2 4 8 16
}
Write-Host "Overviews built for all .tif rasters."


Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host " - Load the generated rasters into QGIS and inspect them." -ForegroundColor Cyan
Write-Host " - Optionally build overviews for faster display: gdaladdo -r average <file> 2 4 8 16" -ForegroundColor Cyan
Write-Host " - Stack bands (RGB + thermal_resampled + dsm_resampled + slope) using gdal_merge.py -separate before classification." -ForegroundColor Cyan

Write-Host "Script finished." -ForegroundColor Green