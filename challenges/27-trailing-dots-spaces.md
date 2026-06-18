---
title: "Challenge 27: Trailing Dots and Spaces"
challenge_number: 27
difficulty: medium
category: "Extension Heuristic Bypass"
permalink: /challenges/27-trailing-dots-spaces/
---

# Challenge 27: Trailing Dots and Spaces

**Difficulty:** Medium  
**Category:** Extension Heuristic Bypass

## Objective

Windows NTFS automatically strips trailing dots and spaces from filenames during file creation. The scanner, however, may analyze the **raw filename string** before the filesystem normalizes it. Your goal is to exploit this discrepancy between what the scanner sees and what the filesystem actually creates.

## Scanner Behavior

- The scanner receives the filename as a raw string and performs `rfind('.')` to find the extension.
- It does **not** strip or normalize trailing dots or spaces before analysis.
- The extension is extracted from the raw string as-is.
- The comparison against the suspicious extension list uses the raw extracted value.
- Meanwhile, the actual file on disk may have a completely different effective name after NTFS normalization.

## Hints

1. Consider the filename `malware.exe.` (with a trailing dot). The scanner's `rfind('.')` finds the **last** dot, which has nothing after it - resulting in an empty extension string.
2. An empty extension matches nothing on the suspicious list, so no warning is issued.
3. But when Windows creates the file, NTFS strips the trailing dot, and the file on disk is actually `malware.exe`.
4. Trailing spaces work similarly: `malware.exe ` may confuse extension parsing while NTFS normalizes it back.

---

[View Solution](../solutions/27-trailing-dots-spaces.md)
