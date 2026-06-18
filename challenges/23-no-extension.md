---
title: "Challenge 23: No Extension At All"
challenge_number: 23
difficulty: easy
category: "Extension Heuristic Bypass"
permalink: /challenges/23-no-extension/
---

# Challenge 23: No Extension At All

**Difficulty:** Easy  
**Category:** Extension Heuristic Bypass

## Objective

The scanner uses `rfind('.')` to locate the last period in a filename and extracts everything after it as the extension. Your goal is to craft a filename that causes the extension extraction logic to fail entirely, resulting in no extension being checked.

## Scanner Behavior

- The scanner calls `rfind('.')` on the filename string.
- If a dot is found, the substring after it is compared to the suspicious extensions list.
- If `rfind('.')` returns "not found" (no dot exists), the scanner has no extension to check and skips the heuristic entirely.
- The file passes through with zero warnings regardless of its actual content or executability.

## Hints

1. Linux executables typically have no file extension at all - they rely on file permissions and magic bytes.
2. On Windows, a file without an extension can still be executed if you invoke it through an explicit handler or interpreter.
3. Consider how `cmd /c`, `start`, or direct path invocation handles extensionless files.
4. What happens if you associate a custom handler with a file that has no extension?

---

[View Solution](../solutions/23-no-extension.md)
