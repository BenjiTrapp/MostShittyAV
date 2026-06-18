---
title: "Solution 02: XOR Encoding"
challenge_number: 02
difficulty: easy
category: "Signature Detection Bypass"
permalink: /solutions/02-xor-encoding/
---

# Solution: XOR Encoding

[Back to Challenge](../challenges/02-xor-encoding.md)

## Overview

Defeat signature detection by XOR-encoding the payload string with a key. The encoded bytes look nothing like the original signature. XOR again with the same key at runtime to recover the original string.

## Working Code

```powershell
# XOR Encoding (run once to generate encoded data)
$key = 0x42
$original = "malware"
$encoded = $original.ToCharArray() | ForEach-Object { [byte][char]$_ -bxor $key }
Write-Host "Encoded bytes: $($encoded -join ',')"
# Output: 47,35,46,53,35,48,39

# XOR Decoding (this is what goes in the payload file)
$key = 0x42
$encodedBytes = @(47, 35, 46, 53, 35, 48, 39)
$decoded = -join ($encodedBytes | ForEach-Object { [char]($_ -bxor $key) })
Write-Host "Decoded: $decoded"
```

### Full Payload Example

```powershell
# Encoded with XOR key 0x42 - scanner sees only integers
$key = 0x42
$data = @(47, 35, 46, 53, 35, 48, 39)

# Decode at runtime
$result = -join ($data | ForEach-Object { [char]($_ -bxor $key) })

# Use the decoded string
Write-Host "Payload loaded: $result"
```

### Encoding Other Signatures

```powershell
# Encode any signature for embedding
function Invoke-XorEncode {
    param([string]$Text, [byte]$Key = 0x42)
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($Text)
    $encoded = $bytes | ForEach-Object { $_ -bxor $Key }
    return $encoded
}

# "trojan" encoded: 54,48,47,44,35,46 (XOR 0x42 -> 0x16,0x30,0x2F,0x2C,0x23,0x2E)
Invoke-XorEncode -Text "trojan" -Key 0x42
# "virus" encoded
Invoke-XorEncode -Text "virus" -Key 0x42
```

## Why It Works

The scanner converts file bytes to lowercase ASCII and searches for exact contiguous signatures. XOR transforms every byte:

| Original | Byte | XOR 0x42 | Result |
|----------|------|----------|--------|
| m        | 0x6D | 0x42     | 0x2F (/) |
| a        | 0x61 | 0x42     | 0x23 (#) |
| l        | 0x6C | 0x42     | 0x2E (.) |
| w        | 0x77 | 0x42     | 0x35 (5) |
| a        | 0x61 | 0x42     | 0x23 (#) |
| r        | 0x72 | 0x42     | 0x30 (0) |
| e        | 0x65 | 0x42     | 0x27 (') |

The scanner would need to know the XOR key and try decoding before matching, but it only performs direct byte comparison. There are 255 possible single-byte keys, and the scanner tries none of them.

## How to Verify

1. Save the decoding payload:
   ```powershell
   @'
   $key = 0x42
   $data = @(47, 35, 46, 53, 35, 48, 39)
   $result = -join ($data | ForEach-Object { [char]($_ -bxor $key) })
   Write-Host "Result: $result"
   '@ | Set-Content "test_xor.ps1"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_xor.ps1
   ```

3. Expected result: **No detection** - the file contains only integers and PowerShell operators, no signature strings.

4. Run the script to confirm it works:
   ```powershell
   powershell -File test_xor.ps1
   # Output: Result: malware
   ```
