---
title: "Challenge 02: XOR Encoding"
challenge_number: 2
difficulty: easy
category: "Signature Detection Bypass"
permalink: /challenges/02-xor-encoding/
---

# Challenge 02: XOR Encoding

**Difficulty:** Easy  
**Category:** Signature Detection Bypass

---

## Objective

Bypass the scanner's signature detection using a cryptographic approach. Your script must reconstruct a blocked string at runtime while storing only transformed (unrecognizable) data on disk.

## Scanner Behavior

The scanner performs static byte-pattern matching against file contents. It searches for the following strings as contiguous byte sequences:

- `malware`
- `virus`
- `trojan`
- `evil_payload`
- `dropper`
- `ransomware`
- `payload.exe`

The scanner reads raw file bytes and checks for exact matches. It does **not** interpret or execute the code. It does **not** perform any decryption or decoding.

## Rules

- Your script must produce one of the blocked strings at runtime.
- The method must involve a mathematical/cryptographic transformation of the data.
- The scanner must not find any signature matches in the file.

## Hints

1. What if each byte in your string was **transformed** using a reversible mathematical operation before being stored?
2. Think about bitwise operations that are their own inverse.
3. If you XOR something twice with the same key, you get the original back.
4. The scanner sees the transformed bytes, not the original string.

---

[View Solution](../solutions/02-xor-encoding.md)
