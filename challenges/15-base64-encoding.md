---
title: "Challenge 15: Base64 Encoding"
challenge_number: 15
difficulty: easy
category: "Non-Printable Ratio Bypass"
permalink: /challenges/15-base64-encoding/
---

# Challenge 15: Base64 Encoding

**Difficulty:** Easy  
**Category:** Non-Printable Ratio Bypass

---

## Objective

Hide binary/non-printable content in a file while keeping the non-printable byte ratio at exactly 0%. The file must still be usable — the original binary data should be recoverable at runtime.

## Scanner Behavior

The scanner calculates the ratio of non-printable bytes to total bytes for any file that is **64 bytes or larger**. A byte is considered "non-printable" if it falls outside the standard printable ASCII range (0x20–0x7E, plus common whitespace like tabs and newlines).

If more than **40%** of the file's bytes are non-printable, the scanner flags the file as suspicious.

The scanner performs this check on the **raw file contents as stored on disk**. It does not execute or interpret the file in any way.

## Rules

- Your file must contain data that, when decoded, produces arbitrary binary content (including non-printable bytes).
- The raw file on disk must have a non-printable byte ratio of 0%.
- The file must be at least 64 bytes in size.
- You must demonstrate that the original binary data is recoverable.

## Hints

1. There's a very common encoding that turns **any** binary data into printable ASCII characters.
2. It's used in email attachments daily.
3. The scanner only sees what's on disk — it doesn't understand what the text *represents*.

---

[View Solution](../solutions/15-base64-encoding.md)
