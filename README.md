<div align="center">

<img src="static/logo.png" alt="AMSI Raccoon Lab Logo" width="500" />

</div>
<br><br>


# 🦝 AMSI Raccoon Lab

### *The World's Most Intentionally Terrible Antivirus Scanner*

[![Nim](https://img.shields.io/badge/Nim-2.0.4-yellow.svg?style=flat-square&logo=nim)](https://nim-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows-0078D6.svg?style=flat-square&logo=windows)](https://www.microsoft.com/windows)
[![Status](https://img.shields.io/badge/status-Educational%20Only-red.svg?style=flat-square)](README.md)

**An educational antimalware simulator built in Nim to demonstrate detection techniques and their bypasses.**

[Features](#-features) • [Quick Start](#quick-start) • [Challenge](#-the-challenge) • [Examples](#-usage-examples) • [Bypass Techniques](docs/BYPASS_TECHNIQUES.md) • [Emergency Recovery](#-emergency-recovery) • [Resources](#-resources)

</div>

---

## 🎯 Overview

**MostShittyAVScanner** is a deliberately simplistic antimalware engine designed for **security research**, **education**, and **red team training**. It implements basic heuristic detection methods that mirror real-world AV engines—but with intentional weaknesses to explore.

> ⚠️ **Disclaimer**: This is NOT production security software. It's an educational tool for understanding antimalware evasion techniques.

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🔍 Detection Engines

- **Signature Scanning**
  - ASCII pattern matching
  - Case-insensitive detection
  - Known malware strings

- **Heuristic Analysis**
  - Suspicious file extensions
  - Non-printable byte ratio analysis
  - Tiny executable detection
  - Entropy-based checks

</td>
<td width="50%">

### 🛠️ Technical Features

- **AMSI Provider Interface**
  - Compatible with Windows AMSI
  - Provider architecture pattern
  - Extensible scanning engine

- **Detailed Logging**
  - Timestamped output
  - Color-coded results
  - Step-by-step analysis

</td>
</tr>
</table>

---

## Quick Start

### Prerequisites

```bash
# Windows with Nim 2.0.4
winget install nim-lang.Nim
```

### Installation

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

### Build & Run

```powershell
# Build and run the standalone scanner
nim c -r src\nim_antimalware_sim.nim tests\01_clean\clean.txt tests\02_signature\malware.ps1

# Build the AMSI Provider DLL
nim c --app:lib --cpu:amd64 --out:src\MostShittyAVWrapper.dll src\nim_amsi_wrapper_dll.nim

# Or use the provided scripts
.\scripts\quick_build.ps1

# Or use the Makefile
make build
make test_all
```

---

## 🎪 The Challenge

> **Can you bypass the engine?**  
> This scanner uses common detection heuristics found in real AV products.  
> Your mission: Evade detection while executing your "payloads"!

### Known Vulnerabilities

- 🔓 Extension checking doesn't enforce blocking
- 🔓 Limited signature database
- 🔓 Uncommon extensions not flagged (`.hta`, `.com`, `.wsf`, `.pif`)
- 🔓 No deep content inspection
- 🔓 Case sensitivity issues
- 🔓 No archive/container scanning

**Try it yourself!** Use `create_bypass_files.ps1` to generate test cases.

---

## 📋 Usage Examples

### Basic Scanning

```powershell
# Scan single file
nim c -r src\nim_antimalware_sim.nim suspicious.exe

# Scan multiple files
nim c -r src\nim_antimalware_sim.nim tests\02_signature\*.ps1
```

### Example Output

```console
[2025-11-08 21:33:26] AMSI: Starting scan for file: infected.txt
[2025-11-08 21:33:26] AMSI: Reading file content...
[2025-11-08 21:33:26] AMSI: File successfully read (41 bytes)
[2025-11-08 21:33:26] AMSI: Checking for known malware signatures...
[2025-11-08 21:33:26] AMSI: Threat detected - Signature found in infected.txt
--------------------------------------------
Result for infected.txt: MALICIOUS ⛔
```

### Testing Bypasses

```powershell
# Test signature bypass (string splitting)
nim c -r src\nim_antimalware_sim.nim tests\02_signature\malware.ps1 tests\02_signature\malware_bypass.ps1

# Test uncommon extensions
nim c -r src\nim_antimalware_sim.nim tests\04_extension\help.hta tests\04_extension\legacy.com

# Test no extension
nim c -r src\nim_antimalware_sim.nim tests\04_extension\malware_no_ext

# Run all test categories
make test_all
```

For a complete reference of all bypass techniques with explanations, see [docs/BYPASS_TECHNIQUES.md](docs/BYPASS_TECHNIQUES.md).

---

## 📁 Project Structure

```
MostShittyAV/
├── src/                               # Source code
│   ├── nim_antimalware_sim.nim        # Main scanner engine (standalone EXE)
│   ├── nim_amsi_wrapper_dll.nim       # AMSI provider DLL wrapper
│   ├── MostShittyAVWrapper.dll        # Compiled DLL (build artifact)
│   └── nim_antimalware_sim.exe        # Compiled EXE (build artifact)
├── tests/                             # Test cases organized by category
│   ├── 01_clean/                      # Baseline benign files
│   ├── 02_signature/                  # Signature detection + bypass
│   ├── 03_encoding/                   # Non-printable ratio + bypass
│   ├── 04_extension/                  # Extension heuristic + bypass
│   ├── 05_small_executable/           # Small executable detection
│   ├── 06_amsi_bypass/                # AMSI-specific bypass techniques
│   └── scripts/                       # Test generation scripts
├── scripts/                           # Build, registration & recovery scripts
│   ├── build_and_register.ps1         # Full build/register workflow (PowerShell)
│   ├── quick_build.ps1                # Quick DLL compilation
│   ├── check_provider_is_running.ps1  # AMSI provider status check
│   └── emergency_unregister.cmd       # Emergency deregistration (CMD.exe)
├── docs/                              # Documentation
│   ├── BYPASS_TECHNIQUES.md           # All bypass techniques explained
│   ├── USAGE_COMPARISON.md            # DLL vs EXE comparison
│   └── TEST_REGISTERED_PROVIDER.md    # Testing with Process Monitor
├── static/                            # Static assets (logo)
├── .github/workflows/                 # CI/CD (GitHub Actions)
├── Makefile                           # Build automation
└── README.md                          # This file
```

---

## 🔬 Detection Methods Explained

### 1. Signature Detection
```nim
const signatures = [
  "malware", "virus", "trojan", "evil_payload",
  "dropper", "ransomware", "payload.exe"
]
```
Simple string matching against known malicious patterns.

### 2. Extension Heuristic
```nim
const suspicious = [
  ".exe", ".dll", ".bat", ".cmd", ".sh", 
  ".ps1", ".scr", ".js", ".vbs", ".jar", ".lnk"
]
```
Flags files with potentially dangerous extensions.

### 3. Non-Printable Byte Analysis
```nim
# Threshold: 40% non-printable bytes
if ratio > 0.40:
  # Possibly packed/obfuscated
```
Detects binary/encoded content that might be malicious.

### 4. Small Executable Check
```nim
if size < 32 and isSuspiciousExtension:
  # Suspicious tiny scripts
```
Catches unusually small executable files.

---

## 🧪 Test File Categories

| Category | Directory | Purpose |
|----------|-----------|---------|
| **Clean** | `tests/01_clean/` | Baseline benign files |
| **Signature** | `tests/02_signature/` | Signature matches + string-splitting bypass |
| **Encoding** | `tests/03_encoding/` | High entropy content + base64/padding bypass |
| **Extension** | `tests/04_extension/` | Extension heuristic + uncommon ext/RTLO/double-ext bypass |
| **Small Scripts** | `tests/05_small_executable/` | Tiny executable detection |
| **AMSI Bypass** | `tests/06_amsi_bypass/` | AMSI-specific bypasses (memory patching, reflection, COM hijacking, etc.) |

See [docs/BYPASS_TECHNIQUES.md](docs/BYPASS_TECHNIQUES.md) for full details on each technique.

---

## 🎓 Educational Value

This project demonstrates:

- ✅ **Basic AV Architecture** - Provider pattern, scan engines
- ✅ **Signature Detection** - Pattern matching limitations
- ✅ **Heuristic Analysis** - Behavioral detection methods
- ✅ **Evasion Techniques** - Common bypass strategies
- ✅ **AMSI Integration** - Windows antimalware interface
- ✅ **Nim Programming** - Systems programming in Nim

---

## 🚨 Emergency Recovery

If the AMSI provider causes instability or needs to be quickly removed:

### Quick Deregistration (CMD.exe as Administrator)

```cmd
scripts\emergency_unregister.cmd
```

### Manual Registry Cleanup

```cmd
reg delete "HKLM\SOFTWARE\Microsoft\AMSI\Providers\{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}" /f
reg delete "HKLM\SOFTWARE\Classes\CLSID\{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}\InprocServer32" /f
reg delete "HKLM\SOFTWARE\Classes\CLSID\{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}" /f
```

### Recovery Options

| Situation | Solution |
|-----------|----------|
| Script works but keys remain | Close all PowerShell/CMD windows, retry |
| DLL missing/deleted | Script still works (manual registry cleanup) |
| System unstable / AMSI crashes | Boot Safe Mode, run `emergency_unregister.cmd` |
| Nothing works | `regedit` > manually delete keys listed above |
| Worst case | System Restore via `rstrui.exe` |

See `scripts/emergency_unregister.cmd` for detailed recovery instructions.

---

## 🔗 Resources

### AMSI Documentation
- [IAntimalwareProvider Interface](https://learn.microsoft.com/en-us/windows/win32/api/amsi/nn-amsi-iantimalwareprovider)
- [AMSI Provider Sample](https://github.com/Microsoft/Windows-classic-samples/tree/main/Samples/AmsiProvider)
- [AMSI Overview](https://learn.microsoft.com/en-us/windows/win32/amsi/antimalware-scan-interface-portal)

### Nim Language
- [Nim Official Website](https://nim-lang.org/)
- [Nim Documentation](https://nim-lang.org/documentation.html)
- [Nim by Example](https://nim-by-example.github.io/)

### Security Research
- [MITRE ATT&CK - Defense Evasion](https://attack.mitre.org/tactics/TA0005/)
- [AV Evasion Techniques](https://www.offensive-security.com/metasploit-unleashed/antivirus-evasion/)

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Legal Notice

**This tool is for educational and research purposes only.**

- ❌ Do not use on systems you don't own or have explicit permission to test
- ❌ Do not use for malicious purposes
- ❌ Not a replacement for real security software
- ✅ Use in controlled lab environments only
- ✅ Understand applicable laws and regulations in your jurisdiction

**The author assumes no liability for misuse of this software.**

---

<div align="center">

### 🦝 Happy Hunting! 

*Made with ❤️ and Nim for the security research community*

**[⭐ Star this repo](../../stargazers)** • **[🐛 Report Bug](../../issues)** • **[💡 Request Feature](../../issues)**

</div>
