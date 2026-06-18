---
title: "Challenge 20: Size Padding (Small Executable)"
challenge_number: 20
difficulty: easy
category: "Small Executable Bypass"
permalink: /challenges/20-size-padding-small-exe/
---

# Challenge 20: Size Padding (Small Executable)

**Difficulty:** Easy  
**Category:** Small Executable Bypass

---

## Objective

The scanner flags very small files that have suspicious executable extensions. Create a functional malicious `.bat` file that performs an action but is NOT flagged by the small executable check.

## Scanner Behavior

The scanner has a "small executable" heuristic that fires when **both** of the following conditions are true:

1. The file is **less than 32 bytes** in total size.
2. The file has a **suspicious extension** (e.g., `.exe`, `.bat`, `.cmd`, `.ps1`, `.vbs`, `.scr`, `.com`).

If both conditions are met, the file is flagged. The rationale is that extremely small executable files are unusual and often indicate droppers, stagers, or test payloads.

Files that are **32 bytes or larger** with suspicious extensions are NOT flagged by this specific check (though other checks may still apply).

## Rules

- Your file must have the `.bat` extension.
- The file must be **32 bytes or larger** to avoid the small executable flag.
- The file must contain a functional command that would execute if run (e.g., a command that creates a file, pings a host, or displays a message).
- The functional part of the file should be short — the challenge is in how you reach the 32-byte threshold without adding executable logic.

## Hints

1. Comments don't execute but they **add bytes** to the file size.
2. How do you write a comment in a batch file? There's a well-known keyword for it.
3. The scanner counts total file size — it doesn't distinguish between code and comments.
4. Even whitespace and blank lines contribute to file size.

---

[View Solution](../solutions/20-size-padding-small-exe.md)
