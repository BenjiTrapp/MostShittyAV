---
title: "Challenge 03: Character Code Construction"
challenge_number: 3
difficulty: easy
category: "Signature Detection Bypass"
permalink: /challenges/03-charcode-construction/
---

# Challenge 03: Character Code Construction

**Difficulty:** Easy  
**Category:** Signature Detection Bypass

---

## Objective

Bypass the scanner's signature detection by representing your payload string as numeric values rather than text. The scanner must see only numbers in your file, not the target string.

## Scanner Behavior

The scanner performs static byte-pattern matching against file contents. It searches for the following strings as contiguous byte sequences:

- `malware`
- `virus`
- `trojan`
- `evil_payload`
- `dropper`
- `ransomware`
- `payload.exe`

The scanner performs a literal byte search. It does **not** interpret numeric literals, arrays, or data structures. If the ASCII text of the signature doesn't appear in the file, the scanner won't flag it.

## Rules

- Your script must reconstruct one of the blocked strings at runtime from numeric character codes.
- The file must not contain any of the blocked strings as readable text.
- The approach must use the numeric representation of characters (ASCII/Unicode code points).

## Hints

1. Every character has a corresponding number. The letter `m` is `109`, `a` is `97`, and so on.
2. What if the scanner only sees an array of integers?
3. Languages have functions to convert numbers back into characters at runtime.
4. An array like `@(109, 97, 108)` looks nothing like the word it represents.

---

[View Solution](../solutions/03-charcode-construction.md)
