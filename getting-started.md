---
layout: default
title: Getting Started
permalink: /getting-started
---

<div class="page-header">
  <img src="{{ '/static/logo_transparent.png' | relative_url }}" alt="AMSI Raccoon Lab" class="hero-logo" style="width: 120px;">
  <h1>Getting Started</h1>
  <p>Set up your environment and tackle your first challenge.</p>
</div>

---

## Prerequisites

- **Windows 10/11** (for AMSI challenges)
- **Nim 2.0.4+** (for building the scanner)
- **PowerShell 5.1+** (pre-installed on Windows 10+)

```bash
# Install Nim via winget
winget install nim-lang.Nim
```

---

## Installation

```powershell
# Clone the repository
git clone https://github.com/yourusername/MostShittyAV.git
cd MostShittyAV

# Allow script execution (if needed)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Generate test files
powershell -ExecutionPolicy Bypass -File tests\scripts\create_test_files.ps1
powershell -ExecutionPolicy Bypass -File tests\scripts\create_bypass_files.ps1
```

---

## Build the Scanner

You have multiple options:

```powershell
# Option 1: Build and run standalone scanner
nim c -r src\nim_antimalware_sim.nim tests\01_clean\clean.txt

# Option 2: Use the quick build script
.\scripts\quick_build.ps1

# Option 3: Use the Makefile
make build
```

---

## Two Modes of Operation

### Standalone Scanner (Recommended for Beginners)

No installation needed. Scan files directly from the command line:

```powershell
.\src\nim_antimalware_sim.exe suspicious.exe
```

### AMSI Provider DLL (Advanced - System Integration)

Registers as a Windows AMSI provider and automatically scans content in PowerShell:

```powershell
# As Administrator
.\scripts\build_and_register.ps1 -BuildAndRegister

# Open NEW PowerShell window - provider auto-loads
Write-Host "MALWARE"  # Will be scanned by AMSI
```

> **Warning:** The AMSI Provider affects system-wide behavior. Use `scripts\emergency_unregister.cmd` if anything goes wrong.

---

## Your First Challenge

Start with **Challenge #01: String Splitting** - the easiest bypass:

1. Try scanning a file containing the word "malware":
   ```powershell
   nim c -r src\nim_antimalware_sim.nim tests\02_signature\malware.ps1
   ```
   Result: **MALICIOUS** (blocked)

2. Now try the bypass version:
   ```powershell
   nim c -r src\nim_antimalware_sim.nim tests\02_signature\malware_bypass.ps1
   ```
   Result: **BENIGN** (passed!)

3. Read [Challenge #01]({{ '/challenges/01-string-splitting/' | relative_url }}) and try writing your own bypass.

---

## Scanning Examples

```powershell
# Scan single file
.\src\nim_antimalware_sim.exe suspicious.exe

# Scan multiple files
.\src\nim_antimalware_sim.exe tests\02_signature\*.ps1

# Scan all test categories
make test_all
```

### Example Output

```console
[2025-11-08 21:33:26] AMSI: Starting scan for file: infected.txt
[2025-11-08 21:33:26] AMSI: Reading file content...
[2025-11-08 21:33:26] AMSI: File successfully read (41 bytes)
[2025-11-08 21:33:26] AMSI: Checking for known malware signatures...
[2025-11-08 21:33:26] AMSI: Threat detected - Signature found in infected.txt
--------------------------------------------
Result for infected.txt: MALICIOUS
```

---

## Recommended Challenge Order

If you're new to AV evasion, follow this progression:

### Week 1: Fundamentals
1. [#01 String Splitting]({{ '/challenges/01-string-splitting/' | relative_url }}) - Learn basic string fragmentation
2. [#04 String Reversal]({{ '/challenges/04-string-reversal/' | relative_url }}) - Understand directionality
3. [#07 Hex Encoding]({{ '/challenges/07-hex-encoding/' | relative_url }}) - Data representation
4. [#14 Download Cradle]({{ '/challenges/14-download-cradle/' | relative_url }}) - Design flaw exploitation

### Week 2: Encoding & Structure
5. [#15 Base64 Encoding]({{ '/challenges/15-base64-encoding/' | relative_url }}) - Beat ratio analysis
6. [#20 Size Padding]({{ '/challenges/20-size-padding-small-exe/' | relative_url }}) - Size threshold abuse
7. [#22 Uncommon Extensions]({{ '/challenges/22-uncommon-extensions/' | relative_url }}) - Extension limits
8. [#23 No Extension]({{ '/challenges/23-no-extension/' | relative_url }}) - Parser tricks

### Week 3: Advanced Evasion
9. [#02 XOR Encoding]({{ '/challenges/02-xor-encoding/' | relative_url }}) - Crypto fundamentals
10. [#12 Unicode Homoglyph]({{ '/challenges/12-unicode-homoglyph/' | relative_url }}) - Unicode attacks
11. [#28 NTFS ADS]({{ '/challenges/28-ntfs-ads/' | relative_url }}) - Filesystem tricks
12. [#30 Polyglot File]({{ '/challenges/30-polyglot-file/' | relative_url }}) - Multi-format abuse

### Week 4: AMSI & Runtime
13. [#31 AMSI Init Failed]({{ '/challenges/31-amsi-init-failed/' | relative_url }}) - .NET internals
14. [#32 Memory Patch]({{ '/challenges/32-amsi-memory-patch/' | relative_url }}) - Low-level patching
15. [#43 ETW Patching]({{ '/challenges/43-etw-patching/' | relative_url }}) - Full stealth

---

## Emergency Recovery

If the AMSI provider causes issues:

```cmd
REM Run CMD.exe as Administrator
scripts\emergency_unregister.cmd
```

Manual cleanup:
```cmd
reg delete "HKLM\SOFTWARE\Microsoft\AMSI\Providers\{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}" /f
reg delete "HKLM\SOFTWARE\Classes\CLSID\{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}" /f
```

---

## Next Steps

- Browse all [Challenges]({{ '/challenges/' | relative_url }})
- Understand the [Scanner Architecture]({{ '/architecture' | relative_url }})
- Check [Solutions]({{ '/solutions/' | relative_url }}) if you get stuck
