---
title: "Challenge 33: PowerShell Downgrade Attack"
challenge_number: 33
difficulty: easy
category: "AMSI Bypass"
permalink: /challenges/33-powershell-downgrade/
---

# Challenge 33: PowerShell Downgrade Attack

**Difficulty:** Easy  
**Category:** AMSI Bypass

---

## Objective

Execute a payload containing known-bad signatures by running it in a PowerShell version that has no AMSI integration. Bypass AMSI entirely by never invoking it in the first place.

## Scanner Behavior

AMSI was introduced in Windows 10 and integrated into PowerShell starting with version 5.0. Every command, script block, and module loaded in PowerShell 5+ is submitted to registered AMSI providers for scanning.

However, the PowerShell executable supports running older engine versions for backward compatibility. PowerShell 2.0 has **zero AMSI awareness** — it was designed years before AMSI existed. If you can invoke the v2 engine, your code runs in a context that never calls any AMSI APIs.

Our AMSI provider (`nim_amsi_wrapper_dll`) only sees content that applications actively submit. If the PowerShell engine never submits anything, the provider is completely blind.

## Rules

- You must execute a payload containing the word `malware` or another detected signature without AMSI flagging it.
- You must use a legitimate PowerShell feature (no external tools).
- The technique must work on a system where the required .NET framework version is installed.

## Hints

1. `powershell.exe` accepts a `-Version` parameter that specifies which engine version to load.
2. Version 2 requires .NET Framework 2.0/3.5 to be installed (it's an optional Windows feature).
3. Check your current version with `$PSVersionTable.PSVersion` and compare behavior between v5 and v2.
4. Some organizations disable PowerShell 2.0 via Group Policy or by removing .NET 2.0/3.5 — this bypass does not work there.

---

[View Solution](../solutions/33-powershell-downgrade.md)
