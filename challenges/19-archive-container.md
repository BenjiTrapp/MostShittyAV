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

The scanner reads raw file bytes and performs its checks on the file as a flat byte stream.
It has **no archive unpacking capability**. Exploit this limitation to deliver a payload
that would be detected if scanned directly — without the scanner ever seeing the malicious
content.

## Scanner Behavior

The scanner operates on whatever file path you give it. When it reads a file, it:

- Scans the raw bytes for signature strings
- Calculates the non-printable byte ratio on the raw bytes
- Computes Shannon entropy on the raw bytes

It does **not**:

- Recognise or parse archive formats (ZIP, RAR, 7z, tar, etc.)
- Decompress or extract contained files
- Follow file format structures or headers
- Recursively scan embedded content

## ⚠️ Important: ZIP Files and the Ratio Check

You might try wrapping the payload directly inside a ZIP and scanning the archive.
This **will not work as a ratio bypass** — a ZIP file is full of compressed binary data
(bytes > 0x7E) and ZIP header structures, so its non-printable ratio almost always
exceeds the 40% threshold. For any real-world archive ≥ 64 bytes the scanner will
**block it** via Check 3 before even checking signatures.

The archive container technique therefore works at the **delivery** level, not at the
scanner level: you scan a *clean dropper script* that downloads or extracts the archive
at runtime. The scanner sees only the clean script; the malicious payload is never
presented to it as a file to scan.

## The Actual Bypass

Write a **dropper script** — a small, fully printable text file — that:

1. Is clean enough to pass all 6 scanner checks on its own, and
2. Retrieves or extracts a separately stored archive at runtime.

The payload inside the archive is never scanned directly.

## Rules

- Your dropper script must pass all scanner checks (no blocking, no signatures).
- The payload inside the archive must be content that **would** be detected if scanned directly.
- The payload must remain extractable and executable after delivery.
- You may use any standard container/archive format.

## Hints

1. What does the scanner actually scan? Only the file path you hand it.
2. A dropper script that *points to* an archive is not the same as the archive itself.
3. Keep the dropper script text-only — low non-printable ratio, no signature strings.
4. The archive can live anywhere: a network share, a URL, a second file the scanner
   never looks at.

---

[View Solution](../solutions/19-archive-container.md)
