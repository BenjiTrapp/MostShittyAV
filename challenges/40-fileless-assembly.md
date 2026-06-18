---
title: "Challenge 40: Fileless .NET Assembly Loading"
challenge_number: 40
difficulty: hard
category: "AMSI Bypass"
permalink: /challenges/40-fileless-assembly/
---

# Challenge 40: Fileless .NET Assembly Loading

**Difficulty:** Hard  
**Category:** AMSI Bypass

---

## Objective

Load and execute a .NET assembly entirely from memory without writing any file to disk. Bypass both the file-based scanner and (on older Windows versions) AMSI by operating exclusively in memory.

## Scanner Behavior

The file-based scanner monitors file creation and reads file contents from disk. If a malicious executable or DLL is written to the filesystem, it will be detected by signature matching.

AMSI in its original form (v1, Windows 10 pre-1903) only scans script content — it does not inspect .NET assemblies loaded via reflection. This means loading a pre-compiled assembly from a byte array bypasses AMSI entirely on these systems.

**Important caveat:** Starting with Windows 10 1903, AMSI v2 added hooks for `Assembly.Load(byte[])`. On these newer systems, the assembly bytes are submitted to AMSI providers for scanning. This challenge targets the gap on pre-1903 systems or scenarios where the assembly content itself does not match signatures.

Our scanner (`nim_amsi_wrapper_dll`) performs string-based signature matching. Compiled .NET assemblies store method names and strings differently than raw scripts, which can evade simple pattern matching.

## Rules

- No files may be written to disk during the attack.
- The payload must execute successfully in memory.
- You must use .NET's built-in assembly loading capabilities.
- The assembly content may be embedded, downloaded, or generated in memory.

## Hints

1. `[Reflection.Assembly]::Load([byte[]]$bytes)` loads an assembly from a byte array in memory — no disk I/O.
2. Pre-compile your payload as a .NET class library (DLL) with a public method to invoke.
3. The byte array can be stored as a Base64 string in your script and decoded at runtime.
4. After loading, use reflection to find and invoke your entry point: `$assembly.GetType("Namespace.Class").GetMethod("Method").Invoke(...)`.
5. On AMSI v2 systems, you may need to combine this with another AMSI bypass (like Challenge 31 or 32) first.

---

[View Solution](../solutions/40-fileless-assembly.md)
