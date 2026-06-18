---
title: "Solution 05: Environment Variable Abuse"
challenge_number: 05
difficulty: medium
category: "Signature Detection Bypass"
permalink: /solutions/05-environment-variable-abuse/
---

# Solution: Environment Variable Abuse

[Back to Challenge](../challenges/05-environment-variable-abuse.md)

## Overview

Defeat signature detection by storing sensitive string fragments in environment variables. The actual values are resolved at runtime by the OS; the file only contains variable references, not the payload string.

## Working Code

```powershell
# Store fragments in environment variables
$env:__X1 = "mal"
$env:__X2 = "ware"

# Reconstruct at runtime - scanner only sees variable names
$result = $env:__X1 + $env:__X2
Write-Host "Loaded: $result"

# Cleanup
Remove-Item Env:__X1
Remove-Item Env:__X2
```

### Alternate Approaches

```powershell
# Using [Environment] class
[Environment]::SetEnvironmentVariable("__PAYLOAD_A", "mal", "Process")
[Environment]::SetEnvironmentVariable("__PAYLOAD_B", "ware", "Process")

$decoded = [Environment]::GetEnvironmentVariable("__PAYLOAD_A") +
           [Environment]::GetEnvironmentVariable("__PAYLOAD_B")
Write-Host $decoded

# Pre-set env vars from a launcher script (separate file)
# launcher.cmd:
#   set __P1=tro
#   set __P2=jan
#   powershell -File payload.ps1

# payload.ps1 (this file is clean of signatures):
$word = $env:__P1 + $env:__P2
Write-Host $word

# Using registry-stored env vars (persistent)
# The value is never in the .ps1 file at all
$word = [Environment]::GetEnvironmentVariable("SECRET_VAR", "User")
Write-Host $word
```

### Multi-Stage Approach

```powershell
# Stage 1: Set env vars (could be a separate process)
$env:__A = "ran"
$env:__B = "som"
$env:__C = "ware"

# Stage 2: Assemble (scanner sees none of the fragments together)
$payload = "$env:__A$env:__B$env:__C"
Write-Host "Assembled: $payload"
```

## Why It Works

When the scanner reads the file, it sees the literal text:

```
$env:__X1 = "mal"
$env:__X2 = "ware"
```

The file bytes contain `"mal"` and `"ware"` as separate strings with many bytes between them (the closing quote, newline, `$env:__X2 = "`, etc.). The scanner searches for the contiguous byte sequence `6D 61 6C 77 61 72 65` ("malware"), but:

- `"mal"` ends at one position
- `"ware"` starts much later in the file
- They are never adjacent

Even if the fragments were on the same line, the variable assignment syntax (`$env:__X1 + $env:__X2`) introduces non-signature bytes between them. Environment variable resolution is a runtime operation that requires executing the PowerShell interpreter - something the static scanner cannot do.

## How to Verify

1. Save the code:
   ```powershell
   @'
   $env:__X1 = "mal"
   $env:__X2 = "ware"
   $result = $env:__X1 + $env:__X2
   Write-Host "Loaded: $result"
   Remove-Item Env:__X1
   Remove-Item Env:__X2
   '@ | Set-Content "test_envvar.ps1"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_envvar.ps1
   ```

3. Expected result: **No detection** - the fragments "mal" and "ware" are never contiguous in the file.

4. Execute to confirm:
   ```powershell
   powershell -File test_envvar.ps1
   # Output: Loaded: malware
   ```
