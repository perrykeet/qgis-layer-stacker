# terrain_derivatives.ps1
# ==================================================
# Generate terrain derivatives from a cleaned DSM
# Preserves Float32, propagates NoData, includes:
# - Slope (degrees)
# - Aspect (degrees)
# - Hillshade
# - Curvature (via TRI)
# - Roughness (via TPI)
# - Color relief (optional visualization)
# ==================================================

Set-StrictMode -Version Latest
Write-Host "Starting terrain derivatives workflow..." -ForegroundColor Cyan

# ------------------------------------------
# STEP 1: Set working folder to script location
# ------------------------------------------
$wd = $PSScriptRoot
Write-Host "Working directory: $wd" -ForegroundColor Cyan

# ------------------------------------------
# STEP 2: Define input DSM
# ------------------------------------------
$inputDSM = Join-Path $wd "Kummen20250618_dsm_clean.tif"

if (-not (Test-Path $inputDSM)) {
    Write-Error "Input DSM not found: $inputDSM"
    exit 1
}
Write-Host "Input DSM found: $inputDSM" -ForegroundColor Green

# ------------------------------------------
# STEP 3: Define output derivative filenames
# ------------------------------------------
$slopeFile     = Join-Path $wd "Kummen20250618_dsm_slope.tif"
$aspectFile    = Join-Path $wd "Kummen20250618_dsm_aspect.tif"
$hillshadeFile = Join-Path $wd "Kummen20250618_dsm_hillshade.tif"
$curvatureFile = Join-Path $wd "Kummen20250618_dsm_curvature.tif"
$roughnessFile = Join-Path $wd "Kummen20250618_dsm_roughness.tif"
$colorReliefFile = Join-Path $wd "Kummen20250618_dsm_colorrelief.tif"
$colorRampFile = Join-Path $wd "color_ramp.txt"  # Optional, create if desired

# ------------------------------------------
# STEP 4: Generate slope
# ------------------------------------------
Write-Host "Generating Slope..."
& gdaldem slope -of GTiff -alg ZevenbergenThorne -s 1 $inputDSM $slopeFile
if ($LASTEXITCODE -ne 0) { Write-Warning "Slope generation failed." }

# ------------------------------------------
# STEP 5: Generate aspect
# ------------------------------------------
Write-Host "Generating Aspect..."
& gdaldem aspect -of GTiff $inputDSM $aspectFile
if ($LASTEXITCODE -ne 0) { Write-Warning "Aspect generation failed." }

# ------------------------------------------
# STEP 6: Generate hillshade
# ------------------------------------------
Write-Host "Generating Hillshade..."
& gdaldem hillshade -of GTiff -z 1 -s 1 $inputDSM $hillshadeFile
if ($LASTEXITCODE -ne 0) { Write-Warning "Hillshade generation failed." }

# ------------------------------------------
# STEP 7: Generate curvature (approximated via TRI)
# ------------------------------------------
Write-Host "Generating Curvature (approximated using TRI)..."
& gdaldem TRI -of GTiff $inputDSM $curvatureFile
if ($LASTEXITCODE -ne 0) { Write-Warning "Curvature generation failed." }

# ------------------------------------------
# STEP 8: Generate roughness (approximated via TPI)
# ------------------------------------------
Write-Host "Generating Roughness..."
& gdaldem TPI -of GTiff $inputDSM $roughnessFile
if ($LASTEXITCODE -ne 0) { Write-Warning "Roughness generation failed." }

# ------------------------------------------
# STEP 9: Generate color relief (optional visualization)
# ------------------------------------------
if (Test-Path $colorRampFile) {
    Write-Host "Generating Color Relief using $colorRampFile..."
    & gdaldem color-relief -of GTiff -co "TILED=YES" $inputDSM $colorRampFile $colorReliefFile
    if ($LASTEXITCODE -ne 0) { Write-Warning "Color Relief generation failed." }
} else {
    Write-Warning "Color ramp file not found: $colorRampFile. Skipping Color Relief."
}

# ------------------------------------------
# DONE
# ------------------------------------------
Write-Host "Terrain derivatives workflow complete." -ForegroundColor Green
Write-Host "Outputs:"
Write-Host "- Slope: $slopeFile"
Write-Host "- Aspect: $aspectFile"
Write-Host "- Hillshade: $hillshadeFile"
Write-Host "- Curvature: $curvatureFile"
Write-Host "- Roughness: $roughnessFile"
Write-Host "- Color Relief: $colorReliefFile"
