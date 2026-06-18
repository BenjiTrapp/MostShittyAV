---
title: "Challenge 22: Uncommon Executable Extensions"
challenge_number: 22
difficulty: easy
category: "Extension Heuristic Bypass"
permalink: /challenges/22-uncommon-extensions/
---

# Challenge 22: Uncommon Executable Extensions

**Difficulty:** Easy  
**Category:** Extension Heuristic Bypass

## Objective

The scanner maintains a hardcoded list of 11 file extensions it considers suspicious:

`.exe`, `.bat`, `.cmd`, `.ps1`, `.vbs`, `.js`, `.wsf`, `.scr`, `.pif`, `.com`, `.hta`

Your goal is to deliver an executable payload using a file extension that is **not** on this list but can still be executed by Windows.

## Scanner Behavior

- The scanner extracts the file extension and compares it against the hardcoded list.
- If the extension matches one of the 11 entries, a **warning** is issued (but the file is never blocked).
- If the extension does not match, the scanner reports nothing at all.
- No further analysis of the file content is performed.

## Hints

1. Windows supports far more executable file types than the 11 listed above.
2. The Windows shell has built-in handlers for many extension types that can execute code.
3. Think about Control Panel applets, installer packages, ClickOnce deployments, and legacy sidebar features.
4. Research which extensions are associated with `rundll32.exe`, `msiexec.exe`, or other system binaries.

---

[View Solution](../solutions/22-uncommon-extensions.md)
