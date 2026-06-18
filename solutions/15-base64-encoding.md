---
title: "Solution 15: Base64 Encoding"
challenge_number: 15
difficulty: easy
category: "Non-Printable Ratio Bypass"
permalink: /solutions/15-base64-encoding/
---

# Solution: Base64 Encoding

[Back to Challenge](../challenges/15-base64-encoding.md)

## Overview

Convert binary payloads to Base64 representation before writing to disk. Base64 uses only printable ASCII characters (A-Z, a-z, 0-9, +, /, =), all of which fall within the 0x20-0x7E range. This reduces the non-printable byte ratio to exactly 0%.

## Working Code

### Encoding a Binary Payload

```powershell
# Original binary payload (shellcode bytes - 100% non-printable)
$payload = [byte[]](0xFC, 0x48, 0x83, 0xE4, 0xF0, 0xE8, 0xC0, 0x00,
                    0x00, 0x00, 0x41, 0x51, 0x41, 0x50, 0x52, 0x51,
                    0x56, 0x48, 0x31, 0xD2, 0x65, 0x48, 0x8B, 0x52,
                    0x60, 0x48, 0x8B, 0x52, 0x18, 0x48, 0x8B, 0x52)

# Encode to Base64 - all output characters are printable ASCII
$encoded = [Convert]::ToBase64String($payload)

# Write ONLY the Base64 string to disk
Set-Content -Path "payload.txt" -Value $encoded -NoNewline
```

### The File on Disk

```
/EiD5PDowAAAAEFRQVBSUVZIMdJlSItSYEiLUhhIi1I=
```

Every single character in this string is in the printable ASCII range (0x20-0x7E). The scanner sees 0% non-printable bytes.

### Runtime Decryption (Separate Execution Context)

```powershell
# Read the Base64 string from disk
$encoded = Get-Content -Path "payload.txt" -Raw

# Decode back to original binary at runtime
$decoded = [Convert]::FromBase64String($encoded)

# $decoded now contains the original shellcode bytes
# [byte[]](0xFC, 0x48, 0x83, 0xE4, ...)
```

### Complete Self-Contained Example

```powershell
# This entire file is 100% printable ASCII on disk
$enc = "/EiD5PDowAAAAEFRQVBSUVZIMdJlSItSYEiLUhhIi1I="

# At runtime, decode and use
$shellcode = [Convert]::FromBase64String($enc)
Write-Host "Decoded $($shellcode.Length) bytes of binary payload"
Write-Host "First byte: 0x$($shellcode[0].ToString('X2'))"
```

## Why It Works

The scanner's non-printable ratio check works as follows:

```
ratio = count(bytes outside 0x20-0x7E) / total_file_size
```

If `ratio > 0.40`, the file is flagged as MALICIOUS.

Base64 encoding uses a 64-character alphabet:
- `A-Z` (0x41-0x5A) - all printable
- `a-z` (0x61-0x7A) - all printable
- `0-9` (0x30-0x39) - all printable
- `+` (0x2B) - printable
- `/` (0x2F) - printable
- `=` (0x3D) - padding, printable

**Every single Base64 output character falls within 0x20-0x7E.** This means:
- Numerator (non-printable count) = 0
- Ratio = 0 / file_size = **0%**
- Threshold (40%) is never reached

The scanner reads the raw file bytes on disk and only sees printable ASCII text. It has no capability to recognize that the text *represents* encoded binary data, nor can it decode it. The actual malicious bytes only exist in memory after runtime decoding.

### Byte Comparison

| Format | File Bytes (hex) | Printable? |
|--------|-----------------|------------|
| Raw binary | `FC 48 83 E4 F0 E8` | No (0% printable) |
| Base64 | `2F 45 69 44 35 50` (`/EiD5P`) | Yes (100% printable) |

## How to Verify

1. Create the test file:
   ```powershell
   $payload = [byte[]](0xFC, 0x48, 0x83, 0xE4, 0xF0, 0xE8, 0xC0, 0x00, 0x00, 0x00, 0x41, 0x51, 0x41, 0x50, 0x52, 0x51, 0x56, 0x48, 0x31, 0xD2, 0x65, 0x48, 0x8B, 0x52, 0x60, 0x48, 0x8B, 0x52, 0x18, 0x48, 0x8B, 0x52)
   $encoded = [Convert]::ToBase64String($payload)
   Set-Content -Path "test_b64.txt" -Value $encoded -NoNewline
   ```

2. Verify the file is all printable:
   ```powershell
   $bytes = [System.IO.File]::ReadAllBytes("test_b64.txt")
   $nonPrintable = ($bytes | Where-Object { $_ -lt 0x20 -or $_ -gt 0x7E }).Count
   Write-Host "File size: $($bytes.Length) bytes"
   Write-Host "Non-printable bytes: $nonPrintable"
   Write-Host "Ratio: $($nonPrintable / $bytes.Length)"
   # Output: Ratio: 0
   ```

3. Run the scanner:
   ```
   nim_antimalware_sim.exe test_b64.txt
   ```

4. Expected result: **No detection** - the non-printable ratio is 0%, well below the 40% threshold.

5. Confirm the binary payload is recoverable:
   ```powershell
   $recovered = [Convert]::FromBase64String((Get-Content "test_b64.txt" -Raw))
   Write-Host "First 4 bytes: $(($recovered[0..3] | ForEach-Object { '0x' + $_.ToString('X2') }) -join ', ')"
   # Output: First 4 bytes: 0xFC, 0x48, 0x83, 0xE4
   ```
