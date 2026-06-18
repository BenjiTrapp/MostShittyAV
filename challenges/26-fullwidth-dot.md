---
title: "Challenge 26: Fullwidth Period Substitution"
challenge_number: 26
difficulty: hard
category: "Extension Heuristic Bypass"
permalink: /challenges/26-fullwidth-dot/
---

# Challenge 26: Fullwidth Period Substitution

**Difficulty:** Hard  
**Category:** Extension Heuristic Bypass

## Objective

The scanner searches for the ASCII period character (U+002E, `.`) to locate and extract file extensions. Your goal is to construct a filename where the "dot" separating the name from the extension is **not** the standard ASCII period, but a visually identical Unicode character with a different codepoint.

## Scanner Behavior

- The scanner uses `rfind('.')` which searches exclusively for the ASCII period (byte `0x2E`).
- If no ASCII period is found, the scanner concludes the file has no extension and skips the heuristic check entirely.
- The scanner performs no Unicode normalization or canonicalization on the filename.
- Visually similar characters from other Unicode blocks are treated as regular filename characters, not as extension separators.

## Hints

1. Unicode's Fullwidth Forms block (U+FF00 - U+FFEF) contains characters that are visually identical to their ASCII counterparts but occupy different codepoints.
2. The fullwidth full stop is U+FF0E (`．`) - it looks exactly like a regular period in most fonts.
3. A filename like `malware．exe` (using U+FF0E) contains no ASCII dot, so the scanner finds no extension.
4. Whether the operating system and filesystem treat these characters as equivalent to ASCII depends on the platform and filesystem driver.

---

[View Solution](../solutions/26-fullwidth-dot.md)
