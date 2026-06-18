---
title: "Solution 06: ROT13 / Caesar Cipher"
challenge_number: 06
difficulty: easy
category: "Signature Detection Bypass"
permalink: /solutions/06-rot13-caesar-cipher/
---

# Solution: ROT13 / Caesar Cipher

[Back to Challenge](../challenges/06-rot13-caesar-cipher.md)

## Overview

Defeat signature detection using ROT13 (a Caesar cipher with shift 13). Each letter is replaced by the letter 13 positions ahead in the alphabet. The scanner sees only the substituted characters, which don't match any signature.

## Working Code

```powershell
# ROT13 decode function
function Invoke-ROT13([string]$text) {
    $result = ""
    foreach ($c in $text.ToCharArray()) {
        if ($c -ge 'a' -and $c -le 'z') {
            $result += [char](((([int][char]$c - 97 + 13) % 26) + 97))
        }
        elseif ($c -ge 'A' -and $c -le 'Z') {
            $result += [char](((([int][char]$c - 65 + 13) % 26) + 65))
        }
        else {
            $result += $c
        }
    }
    return $result
}

# "malware" ROT13-encoded = "znyJner" (with case: "znyjner" all lowercase)
$encoded = "znyjner"
$decoded = Invoke-ROT13 $encoded
Write-Host "Decoded: $decoded"
```

### Encoding Reference

```powershell
# How to encode (run once to get encoded strings)
$original = "malware"
$rot13 = Invoke-ROT13 $original
Write-Host "Encoded: $rot13"  # Output: znyjner

# Other signatures:
# "virus"       -> "ivehf"
# "trojan"      -> "gebwna"
# "ransomware"  -> "enafbzjner"
# "dropper"     -> "qebccre"
# "payload.exe" -> "cnlybnq.rkr"
```

### Multiple Payloads

```powershell
function Invoke-ROT13([string]$text) {
    $result = ""
    foreach ($c in $text.ToCharArray()) {
        if ($c -ge 'a' -and $c -le 'z') {
            $result += [char](((([int][char]$c - 97 + 13) % 26) + 97))
        }
        elseif ($c -ge 'A' -and $c -le 'Z') {
            $result += [char](((([int][char]$c - 65 + 13) % 26) + 65))
        }
        else { $result += $c }
    }
    return $result
}

# None of these encoded strings match scanner signatures
$targets = @("znyjner", "ivehf", "gebwna", "enafbzjner")
foreach ($t in $targets) {
    Write-Host (Invoke-ROT13 $t)
}
```

## Why It Works

ROT13 is a substitution cipher that shifts each letter by 13 positions:

| Original | ROT13 | Bytes in File |
|----------|-------|---------------|
| m (0x6D) | z (0x7A) | 0x7A |
| a (0x61) | n (0x6E) | 0x6E |
| l (0x6C) | y (0x79) | 0x79 |
| w (0x77) | j (0x6A) | 0x6A |
| a (0x61) | n (0x6E) | 0x6E |
| r (0x72) | e (0x65) | 0x65 |
| e (0x65) | r (0x72) | 0x72 |

The scanner searches for `6D 61 6C 77 61 72 65` but the file contains `7A 6E 79 6A 6E 65 72` ("znyjner"). No byte matches the expected position.

To break this, the scanner would need to try all 25 possible Caesar shifts (or specifically recognize ROT13 patterns), but it only performs exact contiguous byte matching with no transformation attempts.

## How to Verify

1. Save the code:
   ```powershell
   @'
   function Invoke-ROT13([string]$text) {
       $result = ""
       foreach ($c in $text.ToCharArray()) {
           if ($c -ge 'a' -and $c -le 'z') {
               $result += [char](((([int][char]$c - 97 + 13) % 26) + 97))
           } elseif ($c -ge 'A' -and $c -le 'Z') {
               $result += [char](((([int][char]$c - 65 + 13) % 26) + 65))
           } else { $result += $c }
       }
       return $result
   }
   $decoded = Invoke-ROT13 "znyjner"
   Write-Host "Result: $decoded"
   '@ | Set-Content "test_rot13.ps1"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_rot13.ps1
   ```

3. Expected result: **No detection** - "znyjner" matches no known signature.

4. Execute to confirm:
   ```powershell
   powershell -File test_rot13.ps1
   # Output: Result: malware
   ```
