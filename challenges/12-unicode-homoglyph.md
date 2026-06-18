---
title: "Challenge 12: Unicode Homoglyph Substitution"
challenge_number: 12
difficulty: hard
category: "Signature Detection Bypass"
permalink: /challenges/12-unicode-homoglyph/
---

# Challenge 12: Unicode Homoglyph Substitution

**Difficulty:** Hard  
**Category:** Signature Detection Bypass

---

## Objective

Bypass the scanner's signature detection by replacing one or more characters in the payload with visually identical characters from different Unicode blocks. The string looks the same to human eyes but has completely different bytes on disk.

## Scanner Behavior

The scanner performs static byte-pattern matching against file contents. It searches for the following strings as exact **ASCII byte sequences**:

- `malware` (bytes: `6D 61 6C 77 61 72 65`)
- `virus`
- `trojan`
- `evil_payload`
- `dropper`
- `ransomware`
- `payload.exe`

The scanner matches against specific byte values corresponding to ASCII characters. It does **not** perform visual similarity analysis, Unicode normalization, or homoglyph detection.

## Rules

- Your script must produce a string that is **visually indistinguishable** from one of the blocked signatures when displayed.
- The file must use homoglyph characters that have different byte representations than their ASCII counterparts.
- The scanner must fail to detect the signature due to the different underlying bytes.
- Bonus: consider whether your script needs the string to be functionally equivalent or just visually equivalent.

## Hints

1. Not all characters that look like `a` are actually `a`. The Cyrillic `а` (U+0430) looks identical to Latin `a` (U+0061) but has completely different bytes.
2. Unicode contains thousands of characters that are visual duplicates of ASCII letters across different scripts (Cyrillic, Greek, mathematical symbols, etc.).
3. Replacing even **one** character with its homoglyph breaks the ASCII byte pattern match.
4. This technique is used in real-world phishing attacks (IDN homograph attacks) and is extremely effective against byte-level scanners.

---

[View Solution](../solutions/12-unicode-homoglyph.md)
