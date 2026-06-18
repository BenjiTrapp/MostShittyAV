---
title: "Challenge 14: Download Cradle (Design Flaw Exploitation)"
challenge_number: 14
difficulty: easy
category: "Signature Detection Bypass"
permalink: /challenges/14-download-cradle/
---

# Challenge 14: Download Cradle (Design Flaw Exploitation)

**Difficulty:** Easy (Design Flaw)  
**Category:** Signature Detection Bypass

---

## Objective

Create a fully functional download cradle (a script that downloads and executes remote content) that passes the scanner. This challenge exploits a fundamental design flaw in the scanner's architecture: it has detection logic for suspicious patterns but fails to act on it properly.

## Scanner Behavior

The scanner has **two** detection mechanisms:

1. **Signature Matching (Blocking):** Checks for exact byte matches of known malware strings. Files containing these are **blocked**.

2. **Suspicious Pattern Detection (Warning Only):** Checks for patterns commonly associated with malicious downloaders:
   - `IEX` / `Invoke-Expression`
   - `WebClient`
   - `DownloadString`
   - `Net.WebClient`
   - `bitstransfer`
   - Other download-related cmdlets

   Files matching these patterns generate a **warning** but are **NOT blocked**. The scanner logs the warning and allows the file through.

## The Design Flaw

The scanner identifies suspicious behavior but only warns about it rather than blocking it. This is a common real-world misconfiguration: detection without enforcement. The scanner effectively tells you "this looks dangerous" and then lets it run anyway.

## Rules

- Your script must be a functional download cradle (capable of downloading content from a URL and executing it).
- The script must pass the scanner (not be blocked).
- You should avoid the signature strings (they DO block), but the suspicious pattern warnings won't stop you.
- Demonstrate understanding of the difference between detection and prevention.

## Hints

1. Read the scanner behavior carefully. What's the difference between a **block** and a **warning**?
2. The suspicious pattern detector fires, logs a warning, and then... does nothing. Your file still passes.
3. You don't even need to obfuscate the download cradle patterns. The scanner won't block them.
4. This challenge is about recognizing that not all detections lead to enforcement -- a critical concept in security evasion.

---

[View Solution](../solutions/14-download-cradle.md)
