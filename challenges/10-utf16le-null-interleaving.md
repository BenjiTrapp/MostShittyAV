---
title: "Challenge 10: UTF-16LE Null Interleaving"
challenge_number: 10
difficulty: medium
category: "Signature Detection Bypass"
permalink: /challenges/10-utf16le-null-interleaving/
---

# Challenge 10: UTF-16LE Null Interleaving

**Difficulty:** Medium  
**Category:** Signature Detection Bypass

---

## Objective

Bypass the scanner's signature detection by exploiting differences between text encoding formats. The scanner matches against one encoding format, but your data is stored in another.

## Scanner Behavior

The scanner performs static byte-pattern matching against file contents. It searches for the following strings as **ASCII/UTF-8 byte sequences**:

- `malware` (bytes: `6D 61 6C 77 61 72 65`)
- `virus`
- `trojan`
- `evil_payload`
- `dropper`
- `ransomware`
- `payload.exe`

The scanner compares signatures byte-by-byte. It expects signatures to appear in standard ASCII encoding (one byte per character, no padding). It does **not** account for alternative text encodings that represent the same characters differently.

## Rules

- Your script must produce one of the blocked strings at runtime.
- You must use UTF-16LE encoding (or similar wide-character encoding) to store the payload.
- The scanner must fail to match due to encoding differences.

## Hints

1. In ASCII/UTF-8, `m` is one byte: `6D`. In UTF-16LE, `m` is two bytes: `6D 00`.
2. The scanner looks for `6D 61 6C 77 61 72 65`. UTF-16LE stores it as `6D 00 61 00 6C 00 77 00 61 00 72 00 65 00`. These are not the same byte patterns.
3. The null bytes (`00`) interleaved between each character break the contiguous ASCII signature.
4. Your script can decode the UTF-16LE bytes back into a usable string at runtime.

---

[View Solution](../solutions/10-utf16le-null-interleaving.md)
