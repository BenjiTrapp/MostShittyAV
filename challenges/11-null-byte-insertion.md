---
title: "Challenge 11: Null Byte Insertion"
challenge_number: 11
difficulty: medium
category: "Signature Detection Bypass"
permalink: /challenges/11-null-byte-insertion/
---

# Challenge 11: Null Byte Insertion

**Difficulty:** Medium  
**Category:** Signature Detection Bypass

---

## Objective

Bypass the scanner's signature detection by inserting null bytes (0x00) into the payload string. The null bytes break the contiguous byte pattern the scanner is looking for, but can be stripped at runtime to recover the original string.

## Scanner Behavior

The scanner performs static byte-pattern matching against file contents. It searches for the following strings as contiguous byte sequences:

- `malware`
- `virus`
- `trojan`
- `evil_payload`
- `dropper`
- `ransomware`
- `payload.exe`

The scanner requires exact, uninterrupted byte matches. **Any** byte inserted between characters of a signature -- including the null byte `0x00` -- will cause the pattern match to fail. The scanner does not strip or ignore null bytes before matching.

## Rules

- Your script must produce one of the blocked strings at runtime.
- You must use null byte insertion to break the signature pattern on disk.
- At runtime, null bytes must be removed to reconstruct the original string.
- The technique should demonstrate understanding of byte-level string manipulation.

## Hints

1. The null byte (`0x00`) is a valid byte value but is invisible in most text displays. It's a "ghost" byte.
2. `m[NUL]a[NUL]l[NUL]w[NUL]a[NUL]r[NUL]e` contains the letters of "malware" but the scanner sees 13 bytes, not 7.
3. In PowerShell, you can represent null bytes as `` `0 `` in strings or as `[char]0` in arrays.
4. Removing all null bytes from a byte array at runtime gives you the clean original string.

---

[View Solution](../solutions/11-null-byte-insertion.md)
