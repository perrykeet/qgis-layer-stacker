# clean_dsm.ps1
# Converts -9999 border pixels in DSM to 0

# --- CONFIGURE PATHS ---
$python = "C:\QGIS 3.40.10\apps\Python312\python.exe"
$gdal_calc = "C:\QGIS 3.40.10\apps\Python312\Scripts\gdal_calc.py"

$inputDSM = Join-Path $PSScriptRoot "Kummen20250618_dsm.tif"
$outputDSM = Join-Path $PSScriptRoot "Kummen20250618_dsm_clean.tif"

# --- RUN CALCULATION ---
Write-Host "Converting -9999 border pixels to 0 for DSM ..."
& $python $gdal_calc `
  -A $inputDSM `
  --outfile=$outputDSM `
  --calc="numpy.where(A==-9999,0,A)" `
  --NoDataValue=0 `
  --type=Float32 `
  --overwrite

Write-Host "Done! Cleaned DSM saved as $outputDSM"
