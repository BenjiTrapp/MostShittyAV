---
title: "Challenge 36: Obfuscated Reflection"
challenge_number: 36
difficulty: hard
category: "AMSI Bypass"
permalink: /challenges/36-obfuscated-reflection/
---

# Challenge 36: Obfuscated Reflection

**Difficulty:** Hard  
**Category:** AMSI Bypass

---

## Objective

Achieve the same result as Challenge 31 (setting the AMSI initialization flag to indicate failure), but without the strings `AmsiUtils` or `amsiInitFailed` appearing anywhere in your script. Evade both the AMSI content scanner and any string-based detection rules.

## Scanner Behavior

After the basic `amsiInitFailed` bypass became widely known, AMSI-aware scanners (including our provider) added detection rules for the bypass itself. The provider now scans for:

- `AmsiUtils` (the class name)
- `amsiInitFailed` (the field name)
- Common patterns like `[Ref].Assembly.GetType()`

If any of these strings appear in the submitted script buffer, the scan flags it as malicious — you are caught trying to bypass the very system scanning you.

This creates a cat-and-mouse game: you must achieve the same reflection-based manipulation without any of the tell-tale strings present in your source code.

## Rules

- The strings `AmsiUtils`, `amsiInitFailed`, `System.Management.Automation.AmsiUtils`, and `[Ref].Assembly` must NOT appear as literal strings in your script.
- The end result must be the same: AMSI is disabled for the session.
- You may not use external files or downloads.
- Everything must execute within a single PowerShell session.

## Hints

1. Strings can be built dynamically using concatenation, format strings, character arrays, or variable substitution.
2. Instead of referencing a type by name, you can search through all loaded assemblies and their types programmatically.
3. `[AppDomain]::CurrentDomain.GetAssemblies()` returns all loaded assemblies — you can filter by partial matches.
4. Field names can be constructed using `-replace`, `-join`, or XOR operations at runtime.
5. Combine multiple techniques: build the type name one way, the field name another way, and access them through a third method.

---

[View Solution](../solutions/36-obfuscated-reflection.md)
