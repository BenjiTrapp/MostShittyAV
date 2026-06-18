---
title: "Challenge 41: DLL Path Hijacking"
challenge_number: 41
difficulty: hard
category: "AMSI Bypass"
permalink: /challenges/41-dll-path-hijacking/
---

# Challenge 41: DLL Path Hijacking

**Difficulty:** Hard  
**Category:** AMSI Bypass

---

## Objective

Exploit the Windows DLL search order to make a process load a fake `amsi.dll` that you control, instead of the legitimate one from System32. Your fake DLL should report all scans as clean.

## Scanner Behavior

When an application (like PowerShell) calls an AMSI function, Windows must first locate and load `amsi.dll`. The standard DLL search order on Windows is:

1. The directory from which the application loaded (application directory)
2. The system directory (`C:\Windows\System32`)
3. The 16-bit system directory
4. The Windows directory
5. The current working directory
6. Directories listed in the PATH environment variable

The legitimate `amsi.dll` lives in System32. However, if a DLL with the same name exists **earlier** in the search order (e.g., in the application directory or a PATH directory you control), Windows will load your copy instead.

Once your fake amsi.dll is loaded, all AMSI API calls go to your implementation. If your `AmsiScanBuffer` always returns `AMSI_RESULT_CLEAN`, no content is ever flagged — the real provider is never consulted.

## Rules

- You must create a DLL named `amsi.dll` that exports the required AMSI functions.
- The DLL must not crash the host process.
- You must place it where the DLL search order will find it before System32.
- You may not modify the real amsi.dll in System32 (requires admin/TrustedInstaller).

## Hints

1. Your fake DLL needs to export at minimum: `AmsiInitialize`, `AmsiScanBuffer`, `AmsiScanString`, and `AmsiUninitialize`.
2. `AmsiScanBuffer` should set the result to `AMSI_RESULT_CLEAN` (0) and return `S_OK` (0).
3. If you can write to any directory in the system PATH, placing your DLL there works.
4. Launching `powershell.exe` from a directory containing your fake amsi.dll will load yours first (current directory search).
5. This technique is blocked by newer Windows features like CIG (Code Integrity Guard) and only works when not enforced.

---

[View Solution](../solutions/41-dll-path-hijacking.md)
