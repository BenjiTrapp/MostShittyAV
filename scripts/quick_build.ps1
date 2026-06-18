# quick_build.ps1
# Quick build script for MostShittyAV AMSI Provider

$PROJECT_ROOT = Split-Path $PSScriptRoot -Parent
$DLL_PATH = Join-Path $PROJECT_ROOT "src\MostShittyAVWrapper.dll"
$SOURCE_PATH = Join-Path $PROJECT_ROOT "src\nim_amsi_wrapper_dll.nim"

Write-Host "Building MostShittyAV AMSI Provider..." -ForegroundColor Cyan

# Remove old DLL
if (Test-Path $DLL_PATH) {
    Remove-Item $DLL_PATH -Force -ErrorAction SilentlyContinue
}

# Build
nim c --app:lib --cpu:amd64 --out:$DLL_PATH $SOURCE_PATH

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild successful!" -ForegroundColor Green
    Write-Host "DLL: $DLL_PATH" -ForegroundColor Gray
    
    # Get file size
    $dll = Get-Item $DLL_PATH
    Write-Host "Size: $([math]::Round($dll.Length / 1KB, 2)) KB" -ForegroundColor Gray
    
    Write-Host "`nTo register (requires Admin):" -ForegroundColor Yellow
    Write-Host "  regsvr32 `"$DLL_PATH`"" -ForegroundColor White
} else {
    Write-Host "`nBuild failed!" -ForegroundColor Red
    exit 1
}
