---
title: "Challenge 07: Hex Encoding"
challenge_number: 7
difficulty: easy
category: "Signature Detection Bypass"
permalink: /challenges/07-hex-encoding/
---

# Challenge 07: Hex Encoding

**Difficulty:** Easy  
**Category:** Signature Detection Bypass

---

## Objective

Bypass the scanner's signature detection by representing your payload string in hexadecimal notation. The scanner looks for ASCII text patterns, not hex digit sequences.

## Scanner Behavior

The scanner performs static byte-pattern matching against file contents. It searches for the following strings as contiguous byte sequences:

- `malware`
- `virus`
- `trojan`
- `evil_payload`
- `dropper`
- `ransomware`
- `payload.exe`

The scanner compares raw bytes in the file against its signature database. It does **not** interpret hex-encoded strings, does not decode `0x` prefixed values, and does not recognize hex pairs as character representations.

## Rules

- Your script must produce one of the blocked strings at runtime.
- The file must store the payload in hexadecimal representation only.
- The scanner must not find any signature match in the file.

## Hints

1. Computers natively think in hexadecimal. Every character can be represented as a two-digit hex value.
2. The letter `m` is `0x6D`, `a` is `0x61`, `l` is `0x6C`... The scanner doesn't recognize this as "mal."
3. Store a hex string like `"6D616C77617265"` and convert it back to text at runtime.
4. Most languages have built-in functions for hex-to-string conversion.

---

[View Solution](../solutions/07-hex-encoding.md)
