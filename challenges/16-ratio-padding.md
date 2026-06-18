---
title: "Challenge 16: Ratio Padding"
challenge_number: 16
difficulty: easy
category: "Non-Printable Ratio Bypass"
permalink: /challenges/16-ratio-padding/
---

# Challenge 16: Ratio Padding

**Difficulty:** Easy  
**Category:** Non-Printable Ratio Bypass

---

## Objective

You have binary shellcode that contains a high proportion of non-printable bytes. This shellcode must remain **intact and unmodified** within the file. Your goal is to get the file past the scanner's non-printable byte ratio check without altering the payload itself.

## Scanner Behavior

The scanner calculates a **global ratio** of non-printable bytes to total file size:

```
ratio = non_printable_bytes / total_file_size
```

If this ratio exceeds **40%** (and the file is at least 64 bytes), the file is flagged as suspicious.

The scanner does not analyze specific sections or regions of the file. It counts all non-printable bytes across the **entire file** and divides by the total size.

## Rules

- Your binary shellcode (containing non-printable bytes) must appear verbatim somewhere in the file.
- The overall file must have a non-printable ratio at or below 40%.
- The file must be at least 64 bytes.
- The shellcode must remain executable/usable — no encoding or transforming it.

## Hints

1. The ratio is `non_printable / total_size`. You can't reduce the numerator (the shellcode is fixed). What about the denominator?
2. What if the file was **much larger** than just the payload?
3. Adding printable content doesn't break anything — but it dilutes the ratio.

---

[View Solution](../solutions/16-ratio-padding.md)
