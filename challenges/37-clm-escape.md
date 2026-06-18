---
title: "Challenge 37: Constrained Language Mode Escape"
challenge_number: 37
difficulty: hard
category: "AMSI Bypass"
permalink: /challenges/37-clm-escape/
---

# Challenge 37: Constrained Language Mode Escape

**Difficulty:** Hard  
**Category:** AMSI Bypass

---

## Objective

Escape PowerShell's Constrained Language Mode (CLM) to regain access to .NET types and then perform an AMSI bypass. This is a two-stage challenge: first break out of the language restriction, then disable AMSI.

## Scanner Behavior

Constrained Language Mode (CLM) is a PowerShell security feature that restricts what the language can do. Under CLM:

- Direct .NET type access is blocked (no `[System.Runtime.InteropServices.Marshal]`)
- Only approved cmdlets and language elements are allowed
- Reflection is heavily restricted
- `Add-Type` is blocked

This means most AMSI bypasses (which rely on .NET Reflection or P/Invoke) are impossible from within CLM. The AMSI provider still scans all content, but CLM prevents you from using the tools needed to disable it.

CLM is typically enforced via AppLocker or WDAC policies. However, certain Windows built-in tools ("Living off the Land Binaries" — LOLBins) execute code in contexts that are not restricted by CLM.

## Rules

- Your starting context is a PowerShell session in Constrained Language Mode (`$ExecutionContext.SessionState.LanguageMode` returns `ConstrainedLanguage`).
- You must achieve Full Language Mode and then disable AMSI.
- You may only use tools already present on a default Windows installation.
- No downloading external executables.

## Hints

1. **MSBuild.exe** can execute inline C# tasks defined in XML project files — these tasks run as full .NET code without CLM restrictions.
2. **InstallUtil.exe** can load .NET assemblies via its `/U` (uninstall) parameter, executing code in the `Uninstall()` method.
3. Custom PowerShell **Runspaces** created programmatically can be configured without CLM, but you need .NET access to create them (chicken-and-egg — solve via a LOLBin first).
4. Check `$ExecutionContext.SessionState.LanguageMode` to verify when you have escaped.
5. The two stages can be combined: your LOLBin payload can both escape CLM and disable AMSI in one step.

---

[View Solution](../solutions/37-clm-escape.md)
