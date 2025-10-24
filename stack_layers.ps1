# stack_layers.ps1
# Stacks multiple raster layers into a single multi-band GeoTIFF

Write-Host "Starting Kummen layer stacking..."

# --- CONFIGURE PATHS ---
# QGIS Python executable
$python = "C:\QGIS 3.40.10\apps\Python312\python.exe"

# gdal_merge.py script (adjust if you saved it elsewhere)
$gdal_merge = "C:\Tools\GDAL\gdal_merge.py"

# Output stacked raster
$outputStack = Join-Path $PSScriptRoot "Kummen20250618_stack.tif"

# Input layers (each Join-Path separately)
$layer1 = Join-Path $PSScriptRoot "nodata_KU-Kummen20250618-visual-orthophoto.tif"
$layer2 = Join-Path $PSScriptRoot "Kummen20250618_dsm_resampled.tif"
$layer3 = Join-Path $PSScriptRoot "Kummen20250618_dsm_slope.tif"

$layers = @($layer1, $layer2, $layer3)

# Optional: set QGIS Python environment variables
$env:PYTHONHOME = "C:\QGIS 3.40.10\apps\Python312"
$env:PYTHONPATH = "C:\QGIS 3.40.10\apps\Python312\Lib"

# --- RUN STACKING ---
Write-Host "Stacking layers into $outputStack ..."
& $python $gdal_merge -separate -o $outputStack @layers

Write-Host "Done! Stack created: $outputStack"
