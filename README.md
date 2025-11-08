<div align="center">

```
888b     d888                   888    .d8888b.  888      d8b 888    888           
8888b   d8888                   888   d88P  Y88b 888      Y8P 888    888           
88888b.d88888                   888   Y88b.      888          888    888           
888Y88888P888  .d88b.  .d8888b  888888 "Y888b.   88888b.  888 888888 888888 888   888
888 Y888P 888 d88""88b 88K      888       "Y88b. 888 "88b 888 888    888    888   888
888  Y8P  888 888  888 "Y8888b. 888         "888 888  888 888 888    888    888   888
888   "   888 Y88..88P      X88 Y88b. Y88b  d88P 888  888 888 Y88b.  Y88b.  Y88b  888
888       888  "Y88P"   88888P'  "Y888 "Y8888P"  888  888 888  "Y888  "Y888  "Y88888
                                                                                888
                                                                           Y8b d88P
                                                                            "Y88P"
```

# 🦝 AMSI Raccoon Lab

### *The World's Most Intentionally Terrible Antivirus Scanner*

[![Nim](https://img.shields.io/badge/Nim-2.0.4-yellow.svg?style=flat-square&logo=nim)](https://nim-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows-0078D6.svg?style=flat-square&logo=windows)](https://www.microsoft.com/windows)
[![Status](https://img.shields.io/badge/status-Educational%20Only-red.svg?style=flat-square)](README.md)

**An educational antimalware simulator built in Nim to demonstrate detection techniques and their bypasses.**

[Features](#-features) • [Quick Start](#-quick-start) • [Challenge](#-the-challenge) • [Examples](#-usage-examples) • [Resources](#-resources)

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

## 🚀 Quick Start

### Prerequisites

```bash
# Windows with Nim 2.0.4
winget install nim-lang.Nim
```

### Installation

```powershell
# Clone the repository
git clone https://github.com/yourusername/AMSI-raaccoon-lab.git
cd AMSI-raaccoon-lab

# Allow script execution (if needed)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Generate test files
.\create_test_files.ps1

# Optional: Generate bypass test files
.\test\create_bypass_files.ps1
```

### Build & Run

```powershell
# Compile and scan files
nim c -r nim_antimalware_sim.nim testfile.txt infected.txt

# Or use the Makefile
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
nim c -r nim_antimalware_sim.nim suspicious.exe

# Scan multiple files
nim c -r nim_antimalware_sim.nim *.txt *.exe *.bat
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
# Generate bypass test files
.\test\create_bypass_files.ps1

# Test double extensions
nim c -r nim_antimalware_sim.nim test\document.pdf.exe

# Test uncommon extensions
nim c -r nim_antimalware_sim.nim test\help.hta test\legacy.com

# Test no extension
nim c -r nim_antimalware_sim.nim test\malware
```

---

## 📁 Project Structure

```
AMSI-raaccoon-lab/
├── 📄 nim_antimalware_sim.nim     # Main scanner engine
├── 📄 create_test_files.ps1        # Test file generator
├── 📄 Makefile                     # Build automation
├── 📄 README.md                    # This file
└── 📁 test/
    ├── 📄 create_bypass_files.ps1  # Bypass technique generator
    ├── 📄 01_clean.txt             # Clean test file
    ├── 📄 02_malware.ps1           # Malicious test file
    └── 📄 ...                      # Various test cases
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

| Category | Files | Purpose |
|----------|-------|---------|
| **Clean** | `clean.txt`, `umlaut.txt` | Baseline benign files |
| **Infected** | `infected.txt`, `trojan_sample.txt` | Signature matches |
| **Binary** | `packed.bin`, `mixed.bin` | High entropy content |
| **Small Scripts** | `tiny.bat` | Tiny executable detection |
| **Encoding** | `utf16.txt` | Character encoding tests |
| **Bypass** | `*.hta`, `*.com`, `no-ext` | Evasion techniques |

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
