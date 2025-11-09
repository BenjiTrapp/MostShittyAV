# quick_build.ps1
# Quick build script for MostShittyAV AMSI Provider

Write-Host "Building MostShittyAV AMSI Provider..." -ForegroundColor Cyan

# Remove old DLL
if (Test-Path "MostShittyAVWrapper.dll") {
    Remove-Item "MostShittyAVWrapper.dll" -Force -ErrorAction SilentlyContinue
}

# Build
nim c --app:lib --cpu:amd64 --out:MostShittyAVWrapper.dll nim_amsi_wrapper_dll.nim

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild successful!" -ForegroundColor Green
    Write-Host "DLL: MostShittyAVWrapper.dll" -ForegroundColor Gray
    
    # Get file size
    $dll = Get-Item "MostShittyAVWrapper.dll"
    Write-Host "Size: $([math]::Round($dll.Length / 1KB, 2)) KB" -ForegroundColor Gray
    
    Write-Host "`nTo register (requires Admin):" -ForegroundColor Yellow
    Write-Host "  regsvr32 `"$($dll.FullName)`"" -ForegroundColor White
} else {
    Write-Host "`nBuild failed!" -ForegroundColor Red
    exit 1
}
