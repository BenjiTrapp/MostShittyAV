# Extension Bypass Test File Creator
# Erstellt verschiedene Dateien zum Testen von Extension-Bypass-Techniken

Write-Host "Creating extension bypass test files..." -ForegroundColor Cyan
Write-Host ""

# Test 1: Double Extension (funktioniert in Windows)
Write-Host "[1] Creating double extension files..." -ForegroundColor Yellow
"This looks like a PDF but is actually an EXE" | Out-File -FilePath "document.pdf.exe" -Encoding ASCII
"This looks like a JPG but is actually a BAT file" | Out-File -FilePath "image.jpg.bat" -Encoding ASCII
"This looks like TXT but is actually PowerShell" | Out-File -FilePath "readme.txt.ps1" -Encoding ASCII
Write-Host "    Created: document.pdf.exe, image.jpg.bat, readme.txt.ps1" -ForegroundColor Green

# Test 2: Trailing Spaces (Windows ignoriert diese)
Write-Host "[2] Creating files with trailing spaces..." -ForegroundColor Yellow
"Executable with trailing space" | Out-File -FilePath "malware.exe " -Encoding ASCII
"Script with multiple trailing spaces" | Out-File -FilePath "script.bat  " -Encoding ASCII
Write-Host "    Created: 'malware.exe ', 'script.bat  ' (with trailing spaces)" -ForegroundColor Green

# Test 3: Trailing Dots (Windows entfernt diese)
Write-Host "[3] Creating files with trailing dots..." -ForegroundColor Yellow
"Executable with trailing dot" | Out-File -FilePath "trojan.exe." -Encoding ASCII
"Script with multiple dots" | Out-File -FilePath "payload.bat..." -Encoding ASCII
Write-Host "    Created: 'trojan.exe.', 'payload.bat...' (with trailing dots)" -ForegroundColor Green

# Test 4: Uncommon but executable extensions
Write-Host "[4] Creating files with uncommon executable extensions..." -ForegroundColor Yellow
"Windows Help Executable" | Out-File -FilePath "help.hta" -Encoding ASCII
"COM executable" | Out-File -FilePath "legacy.com" -Encoding ASCII
"Windows Script Component" | Out-File -FilePath "component.wsf" -Encoding ASCII
"Program Information File" | Out-File -FilePath "old.pif" -Encoding ASCII
Write-Host "    Created: help.hta, legacy.com, component.wsf, old.pif" -ForegroundColor Green

# Test 5: Case variations (Windows ist case-insensitive)
Write-Host "[5] Creating files with case variations..." -ForegroundColor Yellow
"Uppercase EXE" | Out-File -FilePath "VIRUS.EXE" -Encoding ASCII
"Mixed case" | Out-File -FilePath "Malware.BaT" -Encoding ASCII
"Weird case" | Out-File -FilePath "script.Ps1" -Encoding ASCII
Write-Host "    Created: VIRUS.EXE, Malware.BaT, script.Ps1" -ForegroundColor Green

# Test 6: Null-Byte Simulation (im Dateiinhalt, nicht im Namen)
Write-Host "[6] Creating file to test null-byte handling..." -ForegroundColor Yellow
$nullByteContent = "malware.exe" + [char]0 + ".txt SAFE FILE"
[System.IO.File]::WriteAllText("nullbyte_test.txt", $nullByteContent)
Write-Host "    Created: nullbyte_test.txt (contains null-byte in content)" -ForegroundColor Green

# Test 7: No extension files
Write-Host "[7] Creating files without extensions..." -ForegroundColor Yellow
"Executable content without extension" | Out-File -FilePath "suspicious_file" -Encoding ASCII
"Another no-ext file" | Out-File -FilePath "malware" -Encoding ASCII
Write-Host "    Created: suspicious_file, malware (no extensions)" -ForegroundColor Green

# Test 8: Unicode/Special Characters (wenn möglich)
Write-Host "[8] Creating files with special characters..." -ForegroundColor Yellow
try {
    "Unicode fun" | Out-File -FilePath "file．exe" -Encoding UTF8  # Fullwidth dot
    Write-Host "    Created: file．exe (with fullwidth dot)" -ForegroundColor Green
} catch {
    Write-Host "    Could not create unicode filename" -ForegroundColor Red
}

Write-Host ""
Write-Host "All test files created!" -ForegroundColor Green
Write-Host ""
Write-Host "Test these files with:" -ForegroundColor Cyan
Write-Host "  nim c -r ..\nim_antimalware_sim.nim *.exe *.bat *.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Expected bypasses:" -ForegroundColor Yellow
Write-Host "  - Files with uncommon extensions (hta, com, wsf, pif) might pass" -ForegroundColor Gray
Write-Host "  - No extension files will likely pass" -ForegroundColor Gray
Write-Host "  - Case variations should be caught (if scanner normalizes)" -ForegroundColor Gray
Write-Host "  - Trailing spaces/dots depend on how OS vs scanner handles them" -ForegroundColor Gray
