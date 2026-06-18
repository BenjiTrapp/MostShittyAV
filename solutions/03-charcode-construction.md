---
title: "Solution 03: Character Code Construction"
challenge_number: 03
difficulty: easy
category: "Signature Detection Bypass"
permalink: /solutions/03-charcode-construction/
---

# Solution: Character Code Construction

[Back to Challenge](../challenges/03-charcode-construction.md)

## Overview

Defeat signature detection by representing the target string as an array of ASCII integer codes. The scanner sees only numeric literals in the file; the string is assembled at runtime via type conversion.

## Working Code

```powershell
# ASCII codes for "malware": m=109, a=97, l=108, w=119, a=97, r=114, e=101
$chars = @(109, 97, 108, 119, 97, 114, 101)
$word = -join ($chars | ForEach-Object { [char]$_ })
Write-Host $word
```

### Alternate Approaches

```powershell
# Using [System.Text.Encoding]
$bytes = [byte[]]@(109, 97, 108, 119, 97, 114, 101)
$word = [System.Text.Encoding]::ASCII.GetString($bytes)
Write-Host $word

# Using a char array directly
$word = [string]::new([char[]]@([char]109, [char]97, [char]108, [char]119, [char]97, [char]114, [char]101))
Write-Host $word

# Obfuscated with expressions (109 = 100+9, etc.)
$chars = @((100+9), (90+7), (100+8), (120-1), (90+7), (114), (100+1))
$word = -join ($chars | ForEach-Object { [char]$_ })
Write-Host $word
```

### Multiple Signatures

```powershell
# "trojan" = 116, 114, 111, 106, 97, 110
$t = -join (@(116,114,111,106,97,110) | ForEach-Object { [char]$_ })

# "virus" = 118, 105, 114, 117, 115
$v = -join (@(118,105,114,117,115) | ForEach-Object { [char]$_ })

# "ransomware" = 114,97,110,115,111,109,119,97,114,101
$r = -join (@(114,97,110,115,111,109,119,97,114,101) | ForEach-Object { [char]$_ })
```

## Why It Works

The scanner's `containsSignature` function reads raw file bytes and searches for the byte pattern of "malware" (`6D 61 6C 77 61 72 65`). When you write `109, 97, 108`:

- The file contains the ASCII characters `1`, `0`, `9`, `,`, ` `, `9`, `7`, `,`, ` `, `1`, `0`, `8`
- In bytes: `31 30 39 2C 20 39 37 2C 20 31 30 38`
- The scanner looks for `6D 61 6C 77 61 72 65` - these bytes simply do not exist in the file

The `[char]$_` cast is a runtime operation. The scanner has no ability to interpret PowerShell type conversions or evaluate expressions. It only sees the literal text content of the file.

## How to Verify

1. Save the code:
   ```powershell
   @'
   $chars = @(109, 97, 108, 119, 97, 114, 101)
   $word = -join ($chars | ForEach-Object { [char]$_ })
   Write-Host $word
   '@ | Set-Content "test_charcode.ps1"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_charcode.ps1
   ```

3. Expected result: **No detection** - only integers and PowerShell syntax in the file.

4. Execute to confirm functionality:
   ```powershell
   powershell -File test_charcode.ps1
   # Output: malware
   ```
