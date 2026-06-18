---
title: "Challenge 05: Environment Variable Abuse"
challenge_number: 5
difficulty: medium
category: "Signature Detection Bypass"
permalink: /challenges/05-environment-variable-abuse/
---

# Challenge 05: Environment Variable Abuse

**Difficulty:** Medium  
**Category:** Signature Detection Bypass

---

## Objective

Bypass the scanner's signature detection by storing payload fragments outside the file itself, using the operating system's environment as a data store. The scanner only examines file contents -- it cannot see what's in memory or the environment.

## Scanner Behavior

The scanner performs static byte-pattern matching against file contents. It searches for the following strings as contiguous byte sequences:

- `malware`
- `virus`
- `trojan`
- `evil_payload`
- `dropper`
- `ransomware`
- `payload.exe`

The scanner reads **only the bytes on disk**. It does not:
- Inspect environment variables
- Monitor process memory
- Analyze runtime state
- Check the Windows Registry

## Rules

- Your script must produce one of the blocked strings at runtime.
- The blocked string must not appear in the file on disk.
- You must use environment variables as part of your bypass strategy.
- The solution should work on a standard Windows system.

## Hints

1. Where else can you store data that the scanner won't look? The OS provides key-value storage that any process can read.
2. Environment variables are set outside the file and retrieved at runtime.
3. You can split a payload across multiple environment variables and reassemble them.
4. Consider: the scanner checks the file, but your script runs in a **context** with more data available than what's in the file.

---

[View Solution](../solutions/05-environment-variable-abuse.md)
