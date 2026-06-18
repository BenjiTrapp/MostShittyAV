# AMSI Bypass: PowerShell Downgrade (Version 2)
# ================================================
# ACHTUNG: Dies ist eine BILDUNGSDATEI. Nicht auf Produktivsystemen ausfuehren!
#
# TECHNIK: Startet PowerShell Version 2, die AMSI nicht unterstuetzt.
#
# WARUM ES FUNKTIONIERT:
# AMSI wurde erst in Windows 10 / PowerShell 5.0 eingefuehrt.
# PowerShell 2.0 hat keinen AMSI-Hook -- alles was dort ausgefuehrt wird,
# kann nicht von AMSI-Providern gescannt werden.
#
# VORAUSSETZUNG: .NET Framework 2.0/3.5 muss installiert sein
# (Windows Feature: "Windows PowerShell 2.0 Engine")
#
# ERKENNUNG:
# - Unser Scanner erkennt dieses File NICHT als malicious
# - Moderne EDR erkennt den Start von powershell.exe -Version 2
# - Windows Event Logging kann PSv2-Starts protokollieren

# Starte PowerShell v2 (kein AMSI!)
# powershell.exe -Version 2 -Command "Write-Host 'No AMSI here: malware trojan virus'"

# Alternative: Direkt im aktuellen Prozess pruefen
if ($PSVersionTable.PSVersion.Major -le 2) {
    Write-Host "Running in PSv2 - AMSI is NOT active"
    Write-Host "malware trojan virus - unscanned!"
} else {
    Write-Host "Current PS Version: $($PSVersionTable.PSVersion)"
    Write-Host "To bypass AMSI, run: powershell.exe -Version 2"
    Write-Host "Note: Requires .NET 2.0/3.5 feature enabled"
}
