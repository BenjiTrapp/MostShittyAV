---
title: "Solution 04: String Reversal"
challenge_number: 04
difficulty: easy
category: "Signature Detection Bypass"
permalink: /solutions/04-string-reversal/
---

# Solution: String Reversal

[Back to Challenge](../challenges/04-string-reversal.md)

## Overview

Defeat signature detection by storing the target string in reverse order. The scanner performs forward-only substring matching, so "erawlam" never matches the signature "malware".

## Working Code

```powershell
# "malware" reversed = "erawlam"
$rev = "erawlam"
$word = -join ($rev[-1..-($rev.Length)])
Write-Host $word
```

### Alternate Approaches

```powershell
# Using [Array]::Reverse
$rev = "erawlam"
$arr = $rev.ToCharArray()
[Array]::Reverse($arr)
$word = -join $arr
Write-Host $word

# Using a custom reverse function
function Invoke-Reverse([string]$s) {
    $c = $s.ToCharArray()
    [Array]::Reverse($c)
    return -join $c
}
$word = Invoke-Reverse "erawlam"
Write-Host $word

# Multiple reversed signatures
$signatures = @{
    target1 = "erawlam"     # malware
    target2 = "suriV"       # Virus
    target3 = "najort"      # trojan
    target4 = "erawmosnar"  # ransomware
}

foreach ($key in $signatures.Keys) {
    $decoded = -join ($signatures[$key][-1..-($signatures[$key].Length)])
    Write-Host "${key}: $decoded"
}
```

## Why It Works

The scanner's `containsSignature` function performs linear forward scanning through the file bytes, checking if the signature bytes appear as a contiguous subsequence:

- Signature bytes: `6D 61 6C 77 61 72 65` ("malware")
- File contains: `65 72 61 77 6C 61 6D` ("erawlam")

The scanner starts looking for `6D` (m) as the first byte of a match. When it encounters `65` (e), it doesn't match. It then slides forward byte by byte. At no point does it find the sequence `6D 61 6C 77 61 72 65` in order because the bytes appear in exactly the opposite order.

The scanner has no concept of "try reversing the string" - it only does direct contiguous byte matching. String reversal is a runtime operation that the static scanner cannot emulate.

## How to Verify

1. Save the code:
   ```powershell
   @'
   $rev = "erawlam"
   $word = -join ($rev[-1..-($rev.Length)])
   Write-Host $word
   '@ | Set-Content "test_reverse.ps1"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_reverse.ps1
   ```

3. Expected result: **No detection** - "erawlam" does not match any signature in the scanner's database.

4. Execute to confirm:
   ```powershell
   powershell -File test_reverse.ps1
   # Output: malware
   ```

5. Verify the scanner WOULD catch the non-reversed version:
   ```powershell
   Set-Content "test_detected.ps1" -Value 'Write-Host "malware"'
   nim_antimalware_sim.exe test_detected.ps1
   # This triggers detection
   ```
