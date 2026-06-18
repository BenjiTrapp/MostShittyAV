# AMSI Bypass: Chunked/Fragmented Execution
# =============================================
# ACHTUNG: Dies ist eine BILDUNGSDATEI. Nicht auf Produktivsystemen ausfuehren!
#
# TECHNIK: Payload wird in kleine Fragmente aufgeteilt, die einzeln
# durch AMSI gescannt werden. Kein einzelnes Fragment enthaelt die
# vollstaendige Signatur.
#
# WARUM ES FUNKTIONIERT:
# AMSI scannt jeden uebergebenen String/Buffer einzeln. Wenn ein Payload
# in mehrere ScriptBlock-Ausfuehrungen aufgeteilt wird, sieht AMSI
# nie den gesamten Payload auf einmal. Jedes Fragment fuer sich ist harmlos.
#
# ERKENNUNG:
# - Unser Scanner scannt nur die Datei als Ganzes
# - Zur Laufzeit werden die Fragmente einzeln an AMSI uebergeben
# - Kein einzelnes Fragment loest eine Signatur aus

# Fragment 1: Variable definieren (harmlos)
$part1 = "mal"

# Fragment 2: Weitere Variable (harmlos)
$part2 = "ware"

# Fragment 3: Zusammenbau und Ausfuehrung
# AMSI sieht bei jedem Befehl nur den aktuellen Befehl:
# Zeile 1: $part1 = "mal"           -> clean
# Zeile 2: $part2 = "ware"          -> clean
# Zeile 3: $result = $part1 + $part2 -> clean (AMSI sieht nur den Ausdruck)
$result = $part1 + $part2
Write-Host "Assembled across fragments: $result"

# Fortgeschritten: Dot-Sourcing separater Dateien
# Jede Datei ist fuer sich harmlos
Write-Host ""
Write-Host "--- Advanced: Multi-File Fragmentation ---"
Write-Host "File1.ps1: `$global:chunk1 = 'Invoke-'`"
Write-Host "File2.ps1: `$global:chunk2 = 'Expression'`"
Write-Host "File3.ps1: `$cmd = `$global:chunk1 + `$global:chunk2; & `$cmd 'payload'`"
Write-Host "Each file scanned individually - no single file triggers detection"
