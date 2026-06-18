---
title: "Challenge 17: Sub-64 Size Gate"
challenge_number: 17
difficulty: medium
category: "Non-Printable Ratio Bypass"
permalink: /challenges/17-sub64-size-gate/
---

# Challenge 17: Sub-64 Size Gate

**Difficulty:** Medium  
**Category:** Non-Printable Ratio Bypass

---

## Objective

The non-printable ratio check has a minimum file size requirement. Exploit this threshold by crafting functional shellcode or a malicious script that fits **below** the minimum size, completely evading the ratio check.

## Scanner Behavior

The scanner's non-printable byte ratio check **only activates for files that are 64 bytes or larger**. Files smaller than 64 bytes skip this check entirely, regardless of how many non-printable bytes they contain.

This is a deliberate design choice — very small files are assumed to be too tiny to contain meaningful threats, and checking them would produce too many false positives on small binary stubs.

## Rules

- Your file must be **less than 64 bytes** in total size.
- The file must contain non-printable bytes (binary content) that would trigger the ratio check if the file were larger.
- The content should be functional — either valid shellcode or a working script that performs some action.
- Demonstrate that the scanner's ratio check does not fire on your file.

## Hints

1. If the file is too small, the check simply doesn't run. No check means no detection.
2. What's the **minimum viable shellcode** for your target architecture? Some operations can be done in surprisingly few bytes.
3. Think about what can be accomplished in under 64 bytes of raw machine code or a tiny script.
4. x86/x64 has some very compact instruction sequences for common operations.

---

[View Solution](../solutions/17-sub64-size-gate.md)
