---
title: "Solution 09: Type Conversion (StringBuilder with Integer Array)"
challenge_number: 09
difficulty: medium
category: "Signature Detection Bypass"
permalink: /solutions/09-type-conversion/
---

# Solution: Type Conversion (StringBuilder with Integer Array)

[Back to Challenge](../challenges/09-type-conversion.md)

## Overview

Defeat signature detection by storing character codes in an integer array and assembling the string at runtime using `System.Text.StringBuilder`. The scanner sees .NET method calls and numeric arrays, never the target string.

## Working Code

```powershell
# Integer array containing ASCII codes for "malware"
$codes = [int[]]@(109, 97, 108, 119, 97, 114, 101)

# Build string using StringBuilder
$sb = New-Object System.Text.StringBuilder
foreach ($code in $codes) {
    [void]$sb.Append([char]$code)
}

$result = $sb.ToString()
Write-Host "Built: $result"
```

### Alternate Approaches

```powershell
# Using StringBuilder with capacity pre-allocation
$codes = [int[]]@(109, 97, 108, 119, 97, 114, 101)
$sb = [System.Text.StringBuilder]::new($codes.Length)
$codes | ForEach-Object { $sb.Append([char]$_) } | Out-Null
Write-Host $sb.ToString()

# Using AppendChar equivalent via method overload
$sb = New-Object System.Text.StringBuilder
$sb.Append([char]109) | Out-Null  # m
$sb.Append([char]97)  | Out-Null  # a
$sb.Append([char]108) | Out-Null  # l
$sb.Append([char]119) | Out-Null  # w
$sb.Append([char]97)  | Out-Null  # a
$sb.Append([char]114) | Out-Null  # r
$sb.Append([char]101) | Out-Null  # e
Write-Host $sb.ToString()

# Using MemoryStream and StreamWriter
$codes = [byte[]]@(109, 97, 108, 119, 97, 114, 101)
$ms = New-Object System.IO.MemoryStream
$ms.Write($codes, 0, $codes.Length)
$result = [System.Text.Encoding]::ASCII.GetString($ms.ToArray())
$ms.Dispose()
Write-Host $result
```

### Complex Obfuscation with Type System

```powershell
# Store as different numeric types
$data = [System.Collections.ArrayList]::new()
[void]$data.Add([byte]109)
[void]$data.Add([int16]97)
[void]$data.Add([uint32]108)
[void]$data.Add([byte]119)
[void]$data.Add([int16]97)
[void]$data.Add([uint32]114)
[void]$data.Add([byte]101)

$sb = [System.Text.StringBuilder]::new()
foreach ($num in $data) {
    [void]$sb.Append([char][int]$num)
}
Write-Host $sb.ToString()
```

## Why It Works

The scanner reads the raw bytes of the source file and searches for signature patterns. What it finds in this file:

```
$codes = [int[]]@(109, 97, 108, 119, 97, 114, 101)
```

In file bytes, this is:
```
24 63 6F 64 65 73 20 3D 20 5B 69 6E 74 5B 5D 5D 40 28 31 30 39 ...
$  c  o  d  e  s  SP =  SP [  i  n  t  [  ]  ]  @  (  1  0  9  ...
```

The numbers `109, 97, 108` are stored as their ASCII digit representations (`"109"` = `31 30 39`), not as the byte values they represent. The scanner looks for `6D 61 6C 77 61 72 65` but finds only digit characters and punctuation.

The `StringBuilder.Append([char]$code)` call is a runtime .NET method invocation that performs integer-to-character conversion. This is beyond the capability of a static byte pattern scanner.

## How to Verify

1. Save the code:
   ```powershell
   @'
   $codes = [int[]]@(109, 97, 108, 119, 97, 114, 101)
   $sb = New-Object System.Text.StringBuilder
   foreach ($code in $codes) { [void]$sb.Append([char]$code) }
   $result = $sb.ToString()
   Write-Host "Built: $result"
   '@ | Set-Content "test_stringbuilder.ps1"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_stringbuilder.ps1
   ```

3. Expected result: **No detection** - scanner sees method calls and integer literals, not strings.

4. Execute to confirm:
   ```powershell
   powershell -File test_stringbuilder.ps1
   # Output: Built: malware
   ```
