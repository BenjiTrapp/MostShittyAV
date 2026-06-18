---
layout: default
title: Scanner Architecture
permalink: /architecture
---

<div class="page-header">
  <img src="{{ '/static/logo_transparent.png' | relative_url }}" alt="AMSI Raccoon Lab" class="hero-logo" style="width: 120px;">
  <h1>Scanner Architecture</h1>
  <p>Understand the detection engine internals and where its weaknesses lie.</p>
</div>

---

## Overview

The AMSI Raccoon Lab scanner is built in **Nim** and operates in two modes:

| Component | File | Purpose |
|-----------|------|---------|
| Standalone Scanner | `nim_antimalware_sim.nim` | Command-line file scanner (EXE) |
| AMSI Provider | `nim_amsi_wrapper_dll.nim` | Windows AMSI integration (DLL) |

Both share the same detection engine with 6 sequential checks.

---

## Detection Pipeline

Every scanned file passes through these 6 checks **in order**:

![](/static/detection_pipeline.png)

---

## Check 1: Signature Detection

**Action:** BLOCKS  
**Weakness:** Only 7 static strings, no deobfuscation

```nim
const signatures = [
  "malware", "virus", "trojan", "evil_payload",
  "dropper", "ransomware", "payload.exe"
]
```

**How it works:**
1. Read entire file content as raw bytes
2. Convert to lowercase ASCII (only 0x41-0x5A range is lowered)
3. Search for each signature as a contiguous substring
4. If ANY match found: file is **MALICIOUS**

**Exploitable weaknesses:**
- No regex/YARA pattern matching
- Only exact contiguous matches
- No Unicode normalization
- No decoding (Base64, XOR, etc.)
- Only 7 signatures in the database

---

## Check 2: Extension Heuristic

**Action:** WARNING only (never blocks)  
**Weakness:** Does not enforce blocking, limited list

```nim
const suspiciousExtensions = [
  ".exe", ".dll", ".bat", ".cmd", ".sh",
  ".ps1", ".scr", ".js", ".vbs", ".jar", ".lnk"
]
```

**How it works:**
1. Extract extension via `rfind('.')` on the filename
2. Take everything after the last dot
3. Lowercase comparison against the list
4. If match: emit warning, **continue scanning** (does not block)

**Exploitable weaknesses:**
- Uses `rfind('.')` (ASCII only, not Unicode-aware)
- Warning-only design (critical flaw)
- Only 11 extensions in the list
- No magic byte validation
- No content-based type detection

---

## Check 3: Non-Printable Byte Ratio

**Action:** BLOCKS  
**Weakness:** Minimum size gate, global ratio, no decoding

```nim
# Only runs if file size >= 64 bytes
let ratio = non_printable_count / total_bytes
if ratio > 0.40:
  result = MALICIOUS
```

**How it works:**
1. Skip if file size < 64 bytes
2. Count bytes outside the printable ASCII range (0x20-0x7E)
3. Calculate ratio: non-printable / total
4. If ratio > 0.40 (40%): file is **MALICIOUS**

**Exploitable weaknesses:**
- 64-byte minimum size (small files bypass)
- Global ratio (padding dilutes it)
- No Base64 detection/decoding
- No per-section analysis
- No archive unpacking

---

## Check 4: Small Executable Detection

**Action:** BLOCKS  
**Weakness:** Dual condition easily broken

```nim
if file_size < 32 and isSuspiciousExtension(ext):
  result = MALICIOUS
```

**How it works:**
1. Check if file size < 32 bytes
2. Check if extension is in the suspicious list
3. If BOTH conditions met: file is **MALICIOUS**

**Exploitable weaknesses:**
- Requires both conditions (break either one)
- Same limited extension list as Check 2
- Comments/padding easily push past 32 bytes

---

## Check 5: Suspicious Pattern Detection

**Action:** WARNING only (never blocks)  
**Weakness:** Critical design flaw - detects but doesn't enforce

```nim
const suspiciousPatterns = [
  "IEX", "Invoke-Expression",
  "Net.WebClient", "DownloadString",
  "Invoke-WebRequest", "Start-Process"
]
```

**How it works:**
1. Search for known attack tool patterns
2. If found: emit warning, **result is discarded**
3. Scanning continues regardless

**Exploitable weaknesses:**
- `discard` keyword means detection has no effect
- Real attack tools (download cradles, C2 stagers) pass as BENIGN
- No behavioral analysis of detected patterns

---

## Check 6: Entropy Analysis

**Action:** WARNING only (never blocks)  
**Weakness:** Advisory only, high threshold

```nim
# Only runs if file size >= 128 bytes
let entropy = shannonEntropy(content)
if entropy > 7.2:
  # Warning: possibly encrypted/compressed
```

**How it works:**
1. Skip if file size < 128 bytes
2. Calculate Shannon entropy (bits per byte, max 8.0)
3. If entropy > 7.2: emit warning (does not block)

**Exploitable weaknesses:**
- Warning only (encrypted payloads pass)
- 128-byte minimum size
- Does not identify encryption algorithm
- No attempt to decrypt or decompress

---

## AMSI Provider Architecture

> For a comprehensive explanation of AMSI, how it works, and why it's bypassable, see [AMSI Explained]({{ '/amsi-explained' | relative_url }}).

When registered as an AMSI provider, the DLL integrates with Windows:

![](/static/amsi_provider_architecture.png)

**Key points:**
- Runs in the calling process's address space (user-mode)
- Process has full control over its own memory
- COM-based registration (HKLM registry)
- Can be hijacked via HKCU COM override

---

## Known Design Weaknesses Summary

| # | Weakness | Impact | Category |
|---|----------|--------|----------|
| 1 | Extension check doesn't block | High | Design flaw |
| 2 | Suspicious pattern check doesn't block | High | Design flaw |
| 3 | Entropy check doesn't block | Medium | Design flaw |
| 4 | Only 7 signature strings | High | Coverage gap |
| 5 | No deobfuscation engine | High | Evasion gap |
| 6 | No Unicode normalization | High | Encoding gap |
| 7 | No archive/container scanning | Medium | Coverage gap |
| 8 | No PE/ELF structural analysis | High | Analysis gap |
| 9 | Global ratio instead of per-section | Medium | Precision gap |
| 10 | 64-byte minimum for ratio check | Medium | Threshold gap |
| 11 | No behavioral analysis/sandboxing | High | Architecture gap |
| 12 | User-space AMSI (memory accessible) | High | Platform limitation |

---

## Project Structure

```
MostShittyAV/
├── src/
│   ├── nim_antimalware_sim.nim        # Main scanner engine
│   ├── nim_amsi_wrapper_dll.nim       # AMSI provider DLL
│   ├── MostShittyAVWrapper.dll        # Compiled DLL
│   └── nim_antimalware_sim.exe        # Compiled EXE
├── tests/
│   ├── 01_clean/                      # Baseline benign files
│   ├── 02_signature/                  # Signature + bypass tests
│   ├── 03_encoding/                   # Ratio + bypass tests
│   ├── 04_extension/                  # Extension + bypass tests
│   ├── 05_small_executable/           # Small exe tests
│   ├── 06_amsi_bypass/                # AMSI bypass techniques
│   └── scripts/                       # Test generation
├── challenges/                        # Challenge descriptions
├── solutions/                         # Solution walkthroughs
├── scripts/                           # Build & registration
├── docs/                              # Additional documentation
└── static/                            # Logo and assets
```

---

## Further Reading

- [AMSI_EXPLAINED.md](docs/AMSI_EXPLAINED.md) - What AMSI is and how it works
- [BYPASS_TECHNIQUES.md](docs/BYPASS_TECHNIQUES.md) - Full bypass reference
- [USAGE_COMPARISON.md](docs/USAGE_COMPARISON.md) - DLL vs EXE comparison
- [TEST_REGISTERED_PROVIDER.md](docs/TEST_REGISTERED_PROVIDER.md) - Testing with Process Monitor
