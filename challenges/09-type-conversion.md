---
title: "Challenge 09: Type Conversion"
challenge_number: 9
difficulty: medium
category: "Signature Detection Bypass"
permalink: /challenges/09-type-conversion/
---

# Challenge 09: Type Conversion

**Difficulty:** Medium  
**Category:** Signature Detection Bypass

---

## Objective

Bypass the scanner's signature detection by leveraging the .NET type system to construct strings from primitive data types. Use type casting, StringBuilder, or byte array manipulation to assemble the payload at runtime from non-string data.

## Scanner Behavior

The scanner performs static byte-pattern matching against file contents. It searches for the following strings as contiguous byte sequences:

- `malware`
- `virus`
- `trojan`
- `evil_payload`
- `dropper`
- `ransomware`
- `payload.exe`

The scanner examines raw file bytes. It does **not** understand .NET type metadata, does not evaluate expressions, and cannot predict what a sequence of type conversions will produce.

## Rules

- Your script must produce one of the blocked strings at runtime.
- You must use .NET type system features (type casting, byte arrays, StringBuilder, Convert class, etc.).
- The payload string must not appear literally in the file.
- The approach should demonstrate how the type system can be used as an obfuscation layer.

## Hints

1. `[System.Text.StringBuilder]` can append characters one at a time from integer values.
2. A `[byte[]]` array containing `@(109, 97, 108, 119, 97, 114, 101)` is just data until you cast it to a string.
3. `[System.Text.Encoding]::ASCII.GetString()` converts byte arrays to strings at runtime.
4. The scanner sees method calls and numbers, not the resulting string. The type system is your obfuscation layer.

---

[View Solution](../solutions/09-type-conversion.md)
