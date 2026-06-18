---
title: "Solution 01: String Splitting (Concatenation at Runtime)"
challenge_number: 01
difficulty: easy
category: "Signature Detection Bypass"
permalink: /solutions/01-string-splitting/
---

# Solution: String Splitting (Concatenation at Runtime)

[Back to Challenge](../challenges/01-string-splitting.md)

## Overview

Defeat signature detection by splitting the target string into fragments that are concatenated only at runtime. The scanner never sees the complete signature as contiguous bytes in the file.

## Working Code

```powershell
# The word "malware" never appears as a contiguous string in this file
$a = "mal"
$b = "ware"
$payload = $a + $b

Write-Host "Loaded: $payload"
```

### Alternate Approaches

```powershell
# Using -join with an array of fragments
$parts = @("mal", "wa", "re")
$word = -join $parts
Write-Host $word

# Using format strings
$word = "{0}{1}" -f "mal", "ware"
Write-Host $word

# Using StringBuilder
$sb = New-Object System.Text.StringBuilder
$sb.Append("mal") | Out-Null
$sb.Append("ware") | Out-Null
Write-Host $sb.ToString()
```

## Why It Works

The scanner (`nim_antimalware_sim.nim`) uses a `containsSignature` function that converts the file content to lowercase ASCII bytes and searches for contiguous byte sequences matching known signatures like `"malware"`.

When you split the string:
- The file contains `"mal"` at one location and `"ware"` at another
- Between them are other bytes (quotes, variable assignments, newlines)
- The scanner scans left-to-right looking for `6d 61 6c 77 61 72 65` as a contiguous sequence
- It finds `6d 61 6c` followed by non-matching bytes (the `"` and `$b = "` etc.)
- The match fails because the signature bytes are not adjacent

The concatenation (`$a + $b`) only happens at runtime in memory, which a static file scanner never observes.

## How to Verify

1. Save the code to a `.ps1` file:
   ```powershell
   Set-Content -Path "test_split.ps1" -Value '$a = "mal"; $b = "ware"; $payload = $a + $b; Write-Host "Loaded: $payload"'
   ```

2. Run the scanner against it:
   ```
   nim_antimalware_sim.exe test_split.ps1
   ```

3. Expected result: **No detection** - the scanner reports the file as clean because "malware" never appears as contiguous bytes.

4. Compare with a file that DOES contain the full string:
   ```powershell
   Set-Content -Path "test_detected.ps1" -Value 'Write-Host "malware"'
   nim_antimalware_sim.exe test_detected.ps1
   ```
   This will trigger detection.
