---
title: "Challenge 01: String Splitting"
challenge_number: 1
difficulty: easy
category: "Signature Detection Bypass"
permalink: /challenges/01-string-splitting/
---

# Challenge 01: String Splitting

**Difficulty:** Easy  
**Category:** Signature Detection Bypass

---

## Objective

Get a script past the scanner that contains and uses the word "malware" at runtime, without the scanner detecting the signature.

## Scanner Behavior

The scanner performs static byte-pattern matching against file contents. It searches for the following strings as contiguous byte sequences:

- `malware`
- `virus`
- `trojan`
- `evil_payload`
- `dropper`
- `ransomware`
- `payload.exe`

If any of these exact byte patterns are found in your file, the scanner flags the file as malicious and blocks it.

The scanner does **not** execute the code. It only reads the raw bytes of the file on disk.

## Rules

- Your script must produce the string "malware" at runtime (e.g., print it, assign it to a variable, or use it in a command).
- The scanner must not detect any of the listed signatures in your file.
- You may use any scripting language supported by Windows (PowerShell, Batch, VBScript, etc.).

## Hints

1. The scanner only matches **contiguous** byte sequences. What happens if the target string is never stored as one piece in the file?
2. Think about how strings can be **built** at runtime from smaller, innocent-looking fragments.
3. Concatenation is your friend.

---

[View Solution](../solutions/01-string-splitting.md)
