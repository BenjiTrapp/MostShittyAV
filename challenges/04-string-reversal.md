---
title: "Challenge 04: String Reversal"
challenge_number: 4
difficulty: easy
category: "Signature Detection Bypass"
permalink: /challenges/04-string-reversal/
---

# Challenge 04: String Reversal

**Difficulty:** Easy  
**Category:** Signature Detection Bypass

---

## Objective

Bypass the scanner's signature detection by exploiting the fact that it only reads strings in one direction. Store your payload in a form the scanner cannot match, then reconstruct it at runtime.

## Scanner Behavior

The scanner performs static byte-pattern matching against file contents. It searches for the following strings as contiguous byte sequences, reading **left to right**:

- `malware`
- `virus`
- `trojan`
- `evil_payload`
- `dropper`
- `ransomware`
- `payload.exe`

The scanner matches bytes in forward order only. It does **not** check for reversed patterns, anagrams, or any rearrangement of the signature bytes.

## Rules

- Your script must produce one of the blocked strings at runtime.
- The file must not contain any forward-reading instance of the blocked signatures.
- You must exploit the scanner's directional limitation.

## Hints

1. The scanner reads forward. What if your string is stored **backward**?
2. `erawlam` doesn't match `malware` in a forward byte scan.
3. Most languages have built-in methods to reverse a string at runtime.
4. The scanner has no concept of "reading in reverse."

---

[View Solution](../solutions/04-string-reversal.md)
