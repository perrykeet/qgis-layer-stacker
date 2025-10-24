# resample_dsm.ps1
# ==================================================
# Resample the cleaned DSM to match orthophoto resolution/grid
# Keeps Float32 precision, preserves NoData, and prepares for terrain derivatives
# ==================================================

Set-StrictMode -Version Latest
Write-Host "Starting DSM resampling workflow..." -ForegroundColor Cyan

# ------------------------------------------
# STEP 1: Set working folder to script location
# ------------------------------------------
$wd = $PSScriptRoot
Write-Host "Working directory: $wd" -ForegroundColor Cyan

# ------------------------------------------
# STEP 2: Define input and output files
# ------------------------------------------
$inputDSM  = Join-Path $wd "Kummen20250618_dsm_clean.tif"
$outputDSM = Join-Path $wd "Kummen20250618_dsm_clean_resampled.tif"

# ------------------------------------------
# STEP 3: Define target pixel size (adjust to match RGB orthophoto if needed)
# ------------------------------------------
$pixelSizeX = 0.03999  # meters
$pixelSizeY = 0.03999  # meters

# ------------------------------------------
# STEP 4: Sanity check - input file exists
# ------------------------------------------
if (-not (Test-Path $inputDSM)) {
    Write-Error "Missing input DSM file: $inputDSM"
    exit 1
}
Write-Host "Input DSM found: $inputDSM" -ForegroundColor Green

# ------------------------------------------
# STEP 5: Run gdalwarp to resample DSM
# ------------------------------------------
Write-Host "Resampling DSM to pixel size $pixelSizeX x $pixelSizeY m..." -ForegroundColor Cyan
& gdalwarp `
    -tr $pixelSizeX $pixelSizeY `
    -r bilinear `
    -of GTiff `
    -ot Float32 `
    -co "TILED=YES" `
    -co "COMPRESS=DEFLATE" `
    -dstnodata 0 `
    $inputDSM $outputDSM

if ($LASTEXITCODE -ne 0) { 
    Write-Error "gdalwarp failed"; exit 1 
}

# ------------------------------------------
# STEP 6: Done
# ------------------------------------------
Write-Host "Resampled DSM saved as: $outputDSM" -ForegroundColor Green
Write-Host "Workflow complete." -ForegroundColor Cyan
