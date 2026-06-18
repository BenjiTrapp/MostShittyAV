---
title: "Solution 10: UTF-16LE Null Byte Interleaving"
challenge_number: 10
difficulty: medium
category: "Signature Detection Bypass"
permalink: /solutions/10-utf16le-null-interleaving/
---

# Solution: UTF-16LE Null Byte Interleaving

[Back to Challenge](../challenges/10-utf16le-null-interleaving.md)

## Overview

Defeat signature detection by encoding the payload as UTF-16LE (Unicode), which inserts a null byte (0x00) between each ASCII character. The scanner's contiguous ASCII byte matching fails because null bytes interrupt every character pair.

## Working Code

```powershell
# Encode "malware" as UTF-16LE then Base64 for safe storage
$bytes = [System.Text.Encoding]::Unicode.GetBytes("malware")
$encoded = [Convert]::ToBase64String($bytes)
Write-Host "Encoded: $encoded"
# Output: bQBhAGwAdwBhAHIAZQA=

# Decode at runtime (this goes in the payload file)
$encoded = "bQBhAGwAdwBhAHIAZQA="
$bytes = [Convert]::FromBase64String($encoded)
$word = [System.Text.Encoding]::Unicode.GetString($bytes)
Write-Host "Decoded: $word"
```

### Direct UTF-16LE Byte Approach

```powershell
# UTF-16LE bytes for "malware" (note null bytes between each char)
# m=6D00, a=6100, l=6C00, w=7700, a=6100, r=7200, e=6500
$utf16bytes = [byte[]]@(
    0x6D, 0x00,  # m
    0x61, 0x00,  # a
    0x6C, 0x00,  # l
    0x77, 0x00,  # w
    0x61, 0x00,  # a
    0x72, 0x00,  # r
    0x65, 0x00   # e
)
$word = [System.Text.Encoding]::Unicode.GetString($utf16bytes)
Write-Host $word
```

### Multiple Signatures

```powershell
# Pre-encoded signatures (UTF-16LE -> Base64)
$signatures = @{
    s1 = "bQBhAGwAdwBhAHIAZQA="         # malware
    s2 = "dgBpAHIAdQBzAA=="             # virus
    s3 = "dAByAG8AagBhAG4A"             # trojan
    s4 = "cgBhAG4AcwBvAG0AdwBhAHIAZQA=" # ransomware
}

foreach ($key in $signatures.Keys) {
    $bytes = [Convert]::FromBase64String($signatures[$key])
    $decoded = [System.Text.Encoding]::Unicode.GetString($bytes)
    Write-Host "${key}: $decoded"
}
```

## Why It Works

UTF-16LE represents each ASCII character as 2 bytes: the character byte followed by 0x00. Here's what "malware" looks like in different encodings:

**ASCII (what scanner searches for):**
```
6D 61 6C 77 61 72 65
m  a  l  w  a  r  e
```

**UTF-16LE (what's actually stored after decoding from Base64):**
```
6D 00 61 00 6C 00 77 00 61 00 72 00 65 00
m  .  a  .  l  .  w  .  a  .  r  .  e  .
```

The scanner's `containsSignature` function expects `6D` immediately followed by `61`. In UTF-16LE, `6D` is followed by `00` (null). The contiguous sequence `6D 61 6C 77 61 72 65` never appears.

Additionally, the Base64 encoding (`bQBhAGwAdwBhAHIAZQA=`) is yet another layer - it transforms the UTF-16LE bytes into an entirely different character set (A-Z, a-z, 0-9, +, /, =) that bears no resemblance to the original.

## How to Verify

1. Save the code:
   ```powershell
   @'
   $encoded = "bQBhAGwAdwBhAHIAZQA="
   $bytes = [Convert]::FromBase64String($encoded)
   $word = [System.Text.Encoding]::Unicode.GetString($bytes)
   Write-Host "Decoded: $word"
   '@ | Set-Content "test_utf16.ps1"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_utf16.ps1
   ```

3. Expected result: **No detection** - Base64 text contains no signature byte patterns.

4. Execute to confirm:
   ```powershell
   powershell -File test_utf16.ps1
   # Output: Decoded: malware
   ```

5. You can verify the Base64 doesn't contain signatures:
   ```powershell
   # "bQBhAGwAdwBhAHIAZQA=" contains none of: malware, virus, trojan, etc.
   "bQBhAGwAdwBhAHIAZQA=".Contains("malware")  # False
   ```
