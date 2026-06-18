---
title: "Solution 12: Unicode Homoglyph Substitution"
challenge_number: 12
difficulty: hard
category: "Signature Detection Bypass"
permalink: /solutions/12-unicode-homoglyph/
---

# Solution: Unicode Homoglyph Substitution

[Back to Challenge](../challenges/12-unicode-homoglyph.md)

## Overview

Defeat signature detection by replacing ASCII letters with visually identical Unicode characters from other scripts (e.g., Cyrillic). The scanner's `toLowerAsciiByte` function only handles ASCII range bytes (0x41-0x5A, 0x61-0x7A); multi-byte UTF-8 sequences for Cyrillic characters don't match.

## Working Code

```powershell
# Replace ASCII 'a' (U+0061) with Cyrillic 'а' (U+0430)
# Replace ASCII 'e' (U+0065) with Cyrillic 'е' (U+0435)
# Replace ASCII 'o' (U+006F) with Cyrillic 'о' (U+043E)

# This looks like "malware" but contains Cyrillic characters:
# m + а(Cyrillic) + l + w + а(Cyrillic) + r + е(Cyrillic)
$homoglyph = "m`u{0430}lw`u{0430}r`u{0435}"
Write-Host $homoglyph
Write-Host "Length: $($homoglyph.Length)"  # Still 7 characters

# Alternative: build from char codes explicitly
$word = "m" + [char]0x0430 + "lw" + [char]0x0430 + "r" + [char]0x0435
Write-Host $word
```

### Homoglyph Substitution Table

```powershell
# Common ASCII -> Cyrillic/Greek homoglyphs
# ASCII 'a' (U+0061) -> Cyrillic 'а' (U+0430) - visually identical
# ASCII 'e' (U+0065) -> Cyrillic 'е' (U+0435) - visually identical
# ASCII 'o' (U+006F) -> Cyrillic 'о' (U+043E) - visually identical
# ASCII 'c' (U+0063) -> Cyrillic 'с' (U+0441) - visually identical
# ASCII 'p' (U+0070) -> Cyrillic 'р' (U+0440) - visually identical
# ASCII 'x' (U+0078) -> Cyrillic 'х' (U+0445) - visually identical

# Build "malware" with Cyrillic 'а' and 'е'
$m = [char]0x006D  # ASCII m (no Cyrillic equivalent)
$a = [char]0x0430  # Cyrillic а (looks like ASCII a)
$l = [char]0x006C  # ASCII l
$w = [char]0x0077  # ASCII w
$r = [char]0x0072  # ASCII r
$e = [char]0x0435  # Cyrillic е (looks like ASCII e)

$word = "$m$a$l$w$a$r$e"
Write-Host "Word: $word"
Write-Host "Looks like 'malware' but isn't!"
```

### Applied to Other Signatures

```powershell
# "virus" with Cyrillic substitutions
# ASCII 'i' has no perfect Cyrillic homoglyph, but we only need ONE substitution
$virus = "v" + [char]0x0456 + "rus"  # Cyrillic 'і' (U+0456) for 'i'
Write-Host $virus

# "trojan" with Cyrillic 'о' and 'а'
$trojan = "tr" + [char]0x043E + "j" + [char]0x0430 + "n"
Write-Host $trojan

# "payload.exe" with Cyrillic 'а' and 'е'
$payload = "p" + [char]0x0430 + "ylo" + [char]0x0430 + "d." + [char]0x0435 + "x" + [char]0x0435
Write-Host $payload
```

## Why It Works

The scanner's `toLowerAsciiByte` function processes bytes individually:
- Bytes 0x41-0x5A (A-Z) are converted to 0x61-0x7A (a-z)
- Bytes 0x61-0x7A (a-z) pass through unchanged
- All other bytes pass through unchanged

Cyrillic 'а' (U+0430) encodes in UTF-8 as **two bytes**: `D0 B0`. When the scanner encounters these bytes:
1. `D0` - not in ASCII letter range, passes through as-is
2. `B0` - not in ASCII letter range, passes through as-is

The scanner searches for `6D 61 6C 77 61 72 65` but the file contains:
```
6D D0B0 6C 77 D0B0 72 D0B5
m  а     l  w  а     r  е
```

Where ASCII 'a' (`61`) has been replaced with Cyrillic 'а' (`D0 B0`) - a two-byte sequence that doesn't match `61`. The signature pattern is completely broken.

## How to Verify

1. Save the code (ensure UTF-8 encoding):
   ```powershell
   $code = @'
   $word = "m" + [char]0x0430 + "lw" + [char]0x0430 + "r" + [char]0x0435
   Write-Host "Result: $word"
   '@
   [System.IO.File]::WriteAllText("test_homoglyph.ps1", $code, [System.Text.UTF8Encoding]::new($false))
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_homoglyph.ps1
   ```

3. Expected result: **No detection** - Cyrillic bytes don't match ASCII signature patterns.

4. Execute to confirm:
   ```powershell
   powershell -File test_homoglyph.ps1
   # Output: Result: mаlwаrе  (visually identical to "malware")
   ```

5. You can verify the difference programmatically:
   ```powershell
   $real = "malware"
   $fake = "m" + [char]0x0430 + "lw" + [char]0x0430 + "r" + [char]0x0435
   Write-Host "Equal: $($real -eq $fake)"  # False!
   Write-Host "Real bytes: $([System.Text.Encoding]::UTF8.GetBytes($real) -join ' ')"
   Write-Host "Fake bytes: $([System.Text.Encoding]::UTF8.GetBytes($fake) -join ' ')"
   ```
