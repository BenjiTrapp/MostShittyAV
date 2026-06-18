---
title: "Challenge 08: Format String Replace"
challenge_number: 8
difficulty: easy
category: "Signature Detection Bypass"
permalink: /challenges/08-format-string-replace/
---

# Challenge 08: Format String Replace

**Difficulty:** Easy  
**Category:** Signature Detection Bypass

---

## Objective

Bypass the scanner's signature detection by inserting removable noise characters into your payload string. The signature is broken on disk but can be cleanly reconstructed by stripping the noise at runtime.

## Scanner Behavior

The scanner performs static byte-pattern matching against file contents. It searches for the following strings as contiguous byte sequences:

- `malware`
- `virus`
- `trojan`
- `evil_payload`
- `dropper`
- `ransomware`
- `payload.exe`

The scanner requires an **exact contiguous match**. If even a single extra byte exists between the characters of a signature, the pattern match fails.

## Rules

- Your script must produce one of the blocked strings at runtime.
- The file must contain a "corrupted" version of the string with inserted garbage characters.
- At runtime, the garbage must be stripped to reveal the original string.
- You may use any consistent delimiter or noise pattern.

## Hints

1. What if you inserted a character (like `#` or `_`) between every letter of your payload? `m#a#l#w#a#r#e` doesn't match `malware`.
2. At runtime, simply remove all instances of your chosen noise character.
3. String replace operations are available in every language: `-replace`, `.Replace()`, `str_replace`, etc.
4. The noise character just needs to be something that doesn't appear naturally in your payload.

---

[View Solution](../solutions/08-format-string-replace.md)
