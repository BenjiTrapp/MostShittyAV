---
title: "Challenge 19: Archive Container"
challenge_number: 19
difficulty: easy
category: "Non-Printable Ratio Bypass"
permalink: /challenges/19-archive-container/
---

# Challenge 19: Archive Container

**Difficulty:** Easy  
**Category:** Non-Printable Ratio Bypass

---

## Objective

The scanner reads raw file bytes and performs its checks on the file as a flat byte stream. It has **no archive unpacking capability**. Exploit this limitation by hiding malicious content inside a container format that the scanner cannot look into.

## Scanner Behavior

The scanner operates on files as raw byte sequences. When it reads a file, it:

- Scans the raw bytes for signature strings
- Calculates the non-printable byte ratio on the raw bytes
- Computes Shannon entropy on the raw bytes

It does **not**:

- Recognize or parse archive formats (ZIP, RAR, 7z, tar, etc.)
- Decompress or extract contained files
- Follow file format structures or headers
- Recursively scan embedded content

To the scanner, a ZIP file is just a sequence of bytes — some printable, some not. It has no concept of "files inside files."

## Rules

- Place a clearly malicious file (one that would be detected if scanned directly) inside a container format.
- The container file itself must pass all scanner checks.
- The malicious content must be extractable and functional after extraction.
- You may use any standard container/archive format.

## Hints

1. ZIP files are just bytes to the scanner. It can't look inside.
2. Most archive formats compress their contents, which changes the byte patterns entirely.
3. Even an uncompressed archive wraps content in a format structure that breaks signature continuity.
4. Think about what a real attacker would do to smuggle a file past a gateway scanner that can't unpack archives.

---

[View Solution](../solutions/19-archive-container.md)
