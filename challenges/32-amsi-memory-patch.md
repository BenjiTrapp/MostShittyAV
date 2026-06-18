---
title: "Challenge 32: AMSI Memory Patching"
challenge_number: 32
difficulty: hard
category: "AMSI Bypass"
permalink: /challenges/32-amsi-memory-patch/
---

# Challenge 32: AMSI Memory Patching

**Difficulty:** Hard  
**Category:** AMSI Bypass

---

## Objective

Patch the `AmsiScanBuffer` function in memory so that it always returns a result indicating the scanned content is clean. After patching, any content submitted to AMSI should pass without detection.

## Scanner Behavior

AMSI operates as a user-mode DLL (`amsi.dll`) loaded into the process space of applications that use it. When PowerShell calls `AmsiScanBuffer`, execution flows into amsi.dll, which then forwards the buffer to all registered AMSI providers (including our `nim_amsi_wrapper_dll`).

Because amsi.dll is loaded in **your process's address space**, you have full read/write access to its memory pages (with appropriate permission changes). The function `AmsiScanBuffer` is the critical chokepoint — every scan request flows through it before reaching any provider.

If this function is modified to immediately return `S_OK` (0) with an `AMSI_RESULT_CLEAN` result, no buffer will ever reach the provider for inspection.

## Rules

- You must patch the live in-memory copy of `AmsiScanBuffer`.
- After patching, all AMSI scans must return clean.
- You may not modify amsi.dll on disk.
- You may not unload amsi.dll.
- Your patching code itself must not be caught by AMSI (bootstrap problem — solve it).

## Hints

1. `VirtualProtect` (from kernel32.dll) can change memory page protections to make code regions writable.
2. Think about what x86/x64 instructions would make a function immediately return 0 in EAX. On x86, this takes only 3 bytes.
3. You need to find the address of `AmsiScanBuffer` first — `GetProcAddress` works on any loaded DLL.
4. P/Invoke or `Add-Type` in PowerShell lets you call Win32 APIs.
5. The bootstrap problem: your patching code itself gets scanned. Consider obfuscating it or splitting it.

---

[View Solution](../solutions/32-amsi-memory-patch.md)
