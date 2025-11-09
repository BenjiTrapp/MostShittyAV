# MostShittyAV - Usage Comparison

## Two Ways to Use MostShittyAV

MostShittyAV offers **two different components** that can be used independently:

### 🆕 AMSI Provider DLL (New - System Integration)

**File:** `MostShittyAVWrapper.dll`

**What it does:**
- Integrates with Windows AMSI (Anti-Malware Scan Interface)
- Automatically scans content in AMSI-aware applications
- Works system-wide once registered

**Use Cases:**
- ✅ Automatic scanning in PowerShell
- ✅ Integration with Windows Defender
- ✅ System-wide malware detection
- ✅ Real-time protection

**Requirements:**
- ⚠️ Administrator privileges for registration
- ⚠️ Must be registered via `regsvr32` or scripts
- ⚠️ Affects system-wide behavior

**Installation:**
```powershell
# As Administrator
.\build_and_register.ps1 -BuildAndRegister
```

**Testing:**
```powershell
# Start a new PowerShell window - provider auto-loads
Write-Host "MALWARE"  # Will be scanned by AMSI
```

---

### 📦 Standalone Scanner EXE (Original - No Installation)

**File:** `MostShittyAVScanner.exe`

**What it does:**
- Command-line file scanner
- Scans files on-demand
- Works completely independently

**Use Cases:**
- ✅ Quick file scanning
- ✅ Batch file scanning
- ✅ Testing/research
- ✅ Portable scanning tool

**Requirements:**
- ✅ No installation needed
- ✅ No admin privileges required
- ✅ Works immediately

**Usage:**
```powershell
# Scan a single file
.\MostShittyAVScanner.exe malware.exe

# Scan multiple files
.\MostShittyAVScanner.exe file1.ps1 file2.bat file3.dll

# Scan test files
.\MostShittyAVScanner.exe test\02_malware.ps1 test\trojan_sample.txt
```

---

## Feature Comparison

| Feature | AMSI Provider DLL | Standalone Scanner EXE |
|---------|-------------------|------------------------|
| **Installation Required** | Yes (registration) | No |
| **Admin Privileges** | Required | Not required |
| **System Integration** | Yes (AMSI) | No |
| **Automatic Scanning** | Yes | No |
| **On-Demand Scanning** | No | Yes |
| **Portable** | No | Yes |
| **Affects PowerShell** | Yes | No |
| **Works Without Restart** | No (needs new process) | Yes (immediate) |
| **Can Scan Multiple Files** | N/A (automatic) | Yes |
| **Learning/Testing** | ✅ See AMSI internals | ✅ Simple scanner logic |

---

## Which One Should You Use?

### Use the **AMSI Provider DLL** if you want to:
- ✅ Learn how AMSI providers work
- ✅ Test system-wide integration
- ✅ Automatically scan PowerShell commands
- ✅ Integrate with Windows security
- ✅ Study AMSI internals with Process Monitor

**Best for:** Security researchers, AMSI learning, system integration testing

### Use the **Standalone Scanner EXE** if you want to:
- ✅ Quickly scan files
- ✅ Test the scanner logic without system changes
- ✅ Avoid requiring admin privileges
- ✅ Portable scanning tool
- ✅ Batch process files

**Best for:** Quick file scanning, testing scanner logic, casual use

---

## Can I Use Both?

**Yes!** They work completely independently:

1. **Standalone Scanner** can be used anytime without affecting the system
2. **AMSI Provider** runs automatically when registered, affecting AMSI-aware apps
3. Both use the same scanner logic from `nim_antimalware_sim.nim`

---

## Examples

### Example 1: Testing Scanner Logic (Use Standalone EXE)

```powershell
# No installation needed
.\MostShittyAVScanner.exe test\02_malware.ps1
```

Output:
```
[2025-11-09 01:30:00] AMSI: Starting scan for file: test\02_malware.ps1
[2025-11-09 01:30:00] AMSI: Threat detected - Signature found
Result: MALICIOUS
```

### Example 2: Testing AMSI Integration (Use DLL)

```powershell
# Register (as Admin)
.\build_and_register.ps1 -BuildAndRegister

# Open NEW PowerShell window
# Type commands - they're automatically scanned
Write-Host "This is safe"  # ✅ No detection
$malware = "MALWARE"       # ⚠️ May trigger detection
```

### Example 3: Scanning Multiple Files (Use Standalone EXE)

```powershell
# Scan entire test directory
Get-ChildItem test -Recurse -File | ForEach-Object {
    .\MostShittyAVScanner.exe $_.FullName
}
```

### Example 4: Research AMSI Provider Loading (Use DLL + Process Monitor)

```powershell
# Register provider
.\build_and_register.ps1 -BuildAndRegister

# Start Process Monitor with filters
# Launch new PowerShell
# Watch DLL load events in Process Monitor

# See TEST_REGISTERED_PROVIDER.md for detailed steps
```

---

## Technical Details

### Both Components Share:
- Same scanner engine (`nim_antimalware_sim.nim`)
- Same signature detection
- Same heuristics
- Same threat analysis logic

### Differences:
| Aspect | AMSI Provider DLL | Standalone Scanner |
|--------|-------------------|-------------------|
| **Entry Point** | `DllRegisterServer`, `DllGetClassObject` | `main()` |
| **Invocation** | Called by AMSI automatically | Called by user manually |
| **Context** | Runs in host process (PowerShell, etc.) | Runs in own process |
| **Input** | AMSI scan requests | Command-line file paths |
| **Output** | HRESULT codes | Console logs + exit code |

---

## Summary

**TLDR:**

- 🆕 **Want system integration?** → Use `MostShittyAVWrapper.dll` (AMSI Provider)
- 📦 **Want quick file scanning?** → Use `MostShittyAVScanner.exe` (Standalone)
- 🎓 **Learning AMSI?** → Use the DLL + Process Monitor
- 🧪 **Testing scanner logic?** → Use the EXE (faster iteration)
- 🚀 **Not sure?** → Start with the EXE (no installation)

Both are included in the release package - choose what fits your needs!
