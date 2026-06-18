---
title: "Challenge 13: Zero-Width Character Insertion"
challenge_number: 13
difficulty: hard
category: "Signature Detection Bypass"
permalink: /challenges/13-zero-width-characters/
---

# Challenge 13: Zero-Width Character Insertion

**Difficulty:** Hard  
**Category:** Signature Detection Bypass

---

## Objective

Bypass the scanner's signature detection by inserting zero-width Unicode characters within the payload string. These characters are invisible when displayed but exist as real bytes in the file, breaking the scanner's pattern matching.

## Scanner Behavior

The scanner performs static byte-pattern matching against file contents. It searches for the following strings as contiguous byte sequences:

- `malware`
- `virus`
- `trojan`
- `evil_payload`
- `dropper`
- `ransomware`
- `payload.exe`

The scanner matches exact byte patterns. It does **not** strip or ignore any Unicode characters before matching, regardless of whether those characters have visual representation. Every byte between signature characters causes a match failure.

## Rules

- Your script must produce a string that appears as one of the blocked signatures when displayed/printed.
- The file must contain zero-width Unicode characters inserted within the payload string.
- The scanner must fail to match due to the extra bytes.
- You should understand that the "reconstructed" string may still contain zero-width characters unless explicitly stripped.

## Hints

1. Unicode defines several zero-width characters: Zero-Width Space (U+200B), Zero-Width Non-Joiner (U+200C), Zero-Width Joiner (U+200D).
2. These characters render as **nothing** visually -- they have no width, no height, no glyph. But they are real bytes in the file (3 bytes each in UTF-8).
3. Inserting a U+200B between `mal` and `ware` makes the file contain `mal[U+200B]ware` which is 10 bytes, not 7. The scanner sees no match.
4. Most terminals and text displays will show the string as `malware` with no visible difference.

---

[View Solution](../solutions/13-zero-width-characters.md)
