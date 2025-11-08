# create_test_files.ps1
# Erstellt mehrere Testdateien für den Nim Antimalware-Simulator.

$here = Get-Location

Write-Host "Erzeuge Testdateien in $here ..." -ForegroundColor Cyan

# 1) Saubere Textdatei (UTF-8, mit LF/CRLF je nach Plattform)
"Hello, this is a clean file." | Out-File -FilePath .\clean.txt -Encoding utf8
Write-Host " - clean.txt erstellt"

# 2) Infizierte Textdatei (enthält die Signatur MALWARE)
"This file contains MALWARE signature" | Out-File -FilePath .\infected.txt -Encoding utf8
Write-Host " - infected.txt erstellt"

# 3) Noch ein Beispiel mit Trojanschriftzug
"Trojan detected in this sample" | Out-File -FilePath .\trojan_sample.txt -Encoding utf8
Write-Host " - trojan_sample.txt erstellt"

# 4) Saubere Datei mit Umlauten / Sonderzeichen (UTF-8)
"Dies ist eine saubere Datei mit Umlauten: aeoß - Gruße!" | Out-File -FilePath .\umlaut.txt -Encoding utf8
Write-Host " - umlaut.txt erstellt"

# 5) Sehr kleine 'ausführbare' Datei (kleiner als 32 Bytes) mit .bat Endung
#    -> simuliert verdächtige kleine script/exe
"@echo off`necho hi" | Out-File -FilePath .\tiny.bat -Encoding ascii
Write-Host " - tiny.bat erstellt"

# 6) Binärdatei mit hohem Anteil nicht-druckbarer Bytes (z.B. 'gepackt')
$binSize = 1024
$bytes = New-Object byte[] $binSize
# Verwende kryptographisch sicheren RNG (RandomNumberGenerator) für echte Zufallsbytes
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
[System.IO.File]::WriteAllBytes(".\packed.bin", $bytes)
Write-Host " - packed.bin (random bytes) erstellt"

# 7) Kleine Binärdatei mit einige Textanteilen (gemischt) - nützlich zum Testen
$mix = New-Object byte[] 128
$rand = New-Object System.Random
$rand.NextBytes($mix)
# Ein paar ASCII-Buchstaben in den ersten 32 Bytes einfügen (lesbarer Bereich)
[System.Text.Encoding]::ASCII.GetBytes("ThisHasNoMalware") | ForEach-Object -Begin { $i=0 } -Process { $mix[$i] = $_; $i++ }
[System.IO.File]::WriteAllBytes(".\mixed.bin", $mix)
Write-Host " - mixed.bin (gemischt) erstellt"

# 8) UTF-16 LE (Windows Unicode) Datei
"Dies ist UTF-16 Text mit Umlauten und Emoji: aeoßäüY€🦝" | Out-File -FilePath .\utf16.txt -Encoding Unicode
Write-Host " - utf16.txt (UTF-16 LE) erstellt"

# Fertig
Write-Host ""
Write-Host "Alle Testdateien erstellt:" -ForegroundColor Green
Get-ChildItem -Path .\ -Include clean.txt,infected.txt,trojan_sample.txt,umlaut.txt,tiny.bat,packed.bin,mixed.bin,utf16.txt | Format-Table Name,Length

Write-Host ""
Write-Host "Zum Testen mit deinem Nim-Scanner (wenn exe im selben Ordner):" -ForegroundColor Yellow
Write-Host "  .\nim_antimalware_sim.exe .\clean.txt .\infected.txt .\trojan_sample.txt .\packed.bin .\tiny.bat .\umlaut.txt .\mixed.bin .\utf16.txt"
Write-Host ""
Write-Host "Hinweis: Falls PowerShell das Script nicht ausführen darf, starte:"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\create_test_files.ps1"
