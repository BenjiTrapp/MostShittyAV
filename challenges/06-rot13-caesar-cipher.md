---
title: "Challenge 06: ROT13 / Caesar Cipher"
challenge_number: 6
difficulty: easy
category: "Signature Detection Bypass"
permalink: /challenges/06-rot13-caesar-cipher/
---

# Challenge 06: ROT13 / Caesar Cipher

**Difficulty:** Easy  
**Category:** Signature Detection Bypass

---

## Objective

Bypass the scanner's signature detection using a classical substitution cipher. Store the payload string in its ciphered form on disk and decode it at runtime.

## Scanner Behavior

The scanner performs static byte-pattern matching against file contents. It searches for the following strings as contiguous byte sequences:

- `malware`
- `virus`
- `trojan`
- `evil_payload`
- `dropper`
- `ransomware`
- `payload.exe`

The scanner does **not** attempt any form of decryption, substitution reversal, or cipher detection. It simply compares raw bytes against its signature list.

## Rules

- Your script must produce one of the blocked strings at runtime.
- The file must contain only the ciphered version of the string (which won't match any signature).
- You must use a letter-substitution cipher (shift cipher / Caesar cipher).

## Hints

1. Julius Caesar shifted letters in the alphabet to hide military messages. The same idea works here.
2. ROT13 is a special Caesar cipher: shift by 13. Since the English alphabet has 26 letters, applying ROT13 twice gives you the original.
3. `malware` shifted by 13 becomes `znyjner`. The scanner has no idea what `znyjner` means.
4. You just need to implement the reverse shift at runtime.

---

[View Solution](../solutions/06-rot13-caesar-cipher.md)
