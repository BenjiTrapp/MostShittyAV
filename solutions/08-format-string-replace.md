---
title: "Solution 08: Format String / Delimiter Replacement"
challenge_number: 08
difficulty: easy
category: "Signature Detection Bypass"
permalink: /solutions/08-format-string-replace/
---

# Solution: Format String / Delimiter Replacement

[Back to Challenge](../challenges/08-format-string-replace.md)

## Overview

Defeat signature detection by inserting delimiter characters into the target string, then removing them at runtime. The delimiters break the contiguous byte sequence that the scanner needs to find a match.

## Working Code

```powershell
# "malware" with underscore delimiters
$dirty = "m_a_l_w_a_r_e"
$clean = $dirty -replace "_", ""
Write-Host $clean
```

### Alternate Approaches

```powershell
# Using dots as delimiters
$dirty = "m.a.l.w.a.r.e"
$clean = $dirty.Replace(".", "")
Write-Host $clean

# Using multiple different delimiters
$dirty = "m!a@l#w$a%r^e"
$clean = $dirty -replace '[!@#$%^]', ''
Write-Host $clean

# Using a regex character class to remove digits
$dirty = "m1a2l3w4a5r6e"
$clean = $dirty -replace '\d', ''
Write-Host $clean

# Using Split and Join
$dirty = "m-a-l-w-a-r-e"
$clean = ($dirty -split '-') -join ''
Write-Host $clean

# Whitespace padding (spaces between each char)
$dirty = "m a l w a r e"
$clean = $dirty -replace ' ', ''
Write-Host $clean
```

### Applied to Multiple Signatures

```powershell
# All signatures with delimiters - none will trigger detection
$encoded = @{
    sig1 = "m_a_l_w_a_r_e"
    sig2 = "v_i_r_u_s"
    sig3 = "t_r_o_j_a_n"
    sig4 = "r_a_n_s_o_m_w_a_r_e"
    sig5 = "d_r_o_p_p_e_r"
    sig6 = "p_a_y_l_o_a_d_._e_x_e"
}

foreach ($key in $encoded.Keys) {
    $decoded = $encoded[$key] -replace '_', ''
    Write-Host "${key}: $decoded"
}
```

## Why It Works

The scanner's `containsSignature` function searches for the exact byte sequence `6D 61 6C 77 61 72 65` ("malware") as contiguous bytes. When delimiters are inserted:

Original "malware":
```
6D 61 6C 77 61 72 65
m  a  l  w  a  r  e
```

With underscores "m_a_l_w_a_r_e":
```
6D 5F 61 5F 6C 5F 77 5F 61 5F 72 5F 65
m  _  a  _  l  _  w  _  a  _  r  _  e
```

The scanner's substring matching algorithm advances through the file looking for `6D` followed immediately by `61`. But after `6D` it finds `5F` (underscore), which breaks the match. Every signature character is separated by at least one non-matching byte.

The `-replace` operation that removes delimiters is a runtime string manipulation that the static scanner cannot execute.

## How to Verify

1. Save the code:
   ```powershell
   @'
   $dirty = "m_a_l_w_a_r_e"
   $clean = $dirty -replace "_", ""
   Write-Host $clean
   '@ | Set-Content "test_replace.ps1"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_replace.ps1
   ```

3. Expected result: **No detection** - underscores between every character break contiguous matching.

4. Execute to confirm:
   ```powershell
   powershell -File test_replace.ps1
   # Output: malware
   ```

5. Note: Be careful with delimiter choice. Using letters could accidentally form a different signature. Underscores, dots, and digits are safe since they don't appear in the signature list.
