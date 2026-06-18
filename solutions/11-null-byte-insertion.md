---
title: "Solution 11: Null Byte Insertion"
challenge_number: 11
difficulty: medium
category: "Signature Detection Bypass"
permalink: /solutions/11-null-byte-insertion/
---

# Solution: Null Byte Insertion

[Back to Challenge](../challenges/11-null-byte-insertion.md)

## Overview

Defeat signature detection by manually inserting null bytes (0x00) between each character in the byte array. At runtime, filter out the nulls to reconstruct the original string. Any non-matching byte between signature characters breaks the scanner's pattern matching.

## Working Code

```powershell
# "malware" with null bytes inserted between each character
# m=109, NULL=0, a=97, NULL=0, l=108, NULL=0, w=119, NULL=0, a=97, NULL=0, r=114, NULL=0, e=101
$withNulls = @(109, 0, 97, 0, 108, 0, 119, 0, 97, 0, 114, 0, 101)
$clean = $withNulls | Where-Object { $_ -ne 0 }
$word = -join ($clean | ForEach-Object { [char]$_ })
Write-Host $word
```

### Alternate Approaches

```powershell
# Using different separator bytes (0xFF instead of 0x00)
$separated = @(109, 255, 97, 255, 108, 255, 119, 255, 97, 255, 114, 255, 101)
$clean = $separated | Where-Object { $_ -ne 255 }
$word = -join ($clean | ForEach-Object { [char]$_ })
Write-Host $word

# Using a function to interleave and de-interleave
function Remove-Interleaving([byte[]]$data, [byte]$separator = 0) {
    $filtered = $data | Where-Object { $_ -ne $separator }
    return -join ($filtered | ForEach-Object { [char]$_ })
}

$payload = [byte[]]@(109, 0, 97, 0, 108, 0, 119, 0, 97, 0, 114, 0, 101)
$result = Remove-Interleaving $payload 0
Write-Host $result

# Random junk bytes between characters (not just nulls)
$junked = @(109, 42, 97, 17, 108, 255, 119, 3, 97, 200, 114, 88, 101)
# Extract every other byte (even indices)
$word = -join (0..6 | ForEach-Object { [char]$junked[$_ * 2] })
Write-Host $word
```

### Applied to All Signatures

```powershell
function Encode-WithNulls([string]$text) {
    $result = @()
    foreach ($c in $text.ToCharArray()) {
        $result += [byte][char]$c
        $result += 0
    }
    # Remove trailing null
    return $result[0..($result.Length - 2)]
}

function Decode-WithNulls([int[]]$data) {
    $clean = $data | Where-Object { $_ -ne 0 }
    return -join ($clean | ForEach-Object { [char]$_ })
}

# Pre-encoded payloads
$trojanEncoded = @(116, 0, 114, 0, 111, 0, 106, 0, 97, 0, 110)
$virusEncoded = @(118, 0, 105, 0, 114, 0, 117, 0, 115)

Write-Host (Decode-WithNulls $trojanEncoded)
Write-Host (Decode-WithNulls $virusEncoded)
```

## Why It Works

The scanner's `containsSignature` performs a contiguous byte scan. It expects to find:
```
6D 61 6C 77 61 72 65
m  a  l  w  a  r  e
```

With null bytes inserted, the byte array (as stored numerically in the file) represents a pattern where the scanner would need to see:
```
Position: [0]  [1]  [2]  [3]  [4]  [5]  [6]  [7]  [8]  [9]  [10] [11] [12]
Value:     6D   00   61   00   6C   00   77   00   61   00   72   00   65
Char:      m   NUL   a   NUL   l   NUL   w   NUL   a   NUL   r   NUL   e
```

But more importantly, in the **source file itself**, these are stored as ASCII digit strings: `"109, 0, 97, 0, 108..."`. The file bytes are `31 30 39 2C 20 30 2C 20 39 37...` - entirely numeric characters that bear no resemblance to the signature bytes.

This technique works on two levels:
1. The integers are stored as decimal text (not binary values)
2. Even if interpreted as binary, the null bytes break contiguous matching

## How to Verify

1. Save the code:
   ```powershell
   @'
   $withNulls = @(109, 0, 97, 0, 108, 0, 119, 0, 97, 0, 114, 0, 101)
   $clean = $withNulls | Where-Object { $_ -ne 0 }
   $word = -join ($clean | ForEach-Object { [char]$_ })
   Write-Host $word
   '@ | Set-Content "test_nullbytes.ps1"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_nullbytes.ps1
   ```

3. Expected result: **No detection** - file contains only integers and PowerShell syntax.

4. Execute to confirm:
   ```powershell
   powershell -File test_nullbytes.ps1
   # Output: malware
   ```
