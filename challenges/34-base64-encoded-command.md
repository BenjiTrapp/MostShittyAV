---
title: "Challenge 34: Base64 Encoded Command"
challenge_number: 34
difficulty: easy
category: "AMSI Bypass"
permalink: /challenges/34-base64-encoded-command/
---

# Challenge 34: Base64 Encoded Command

**Difficulty:** Easy  
**Category:** AMSI Bypass

---

## Objective

Execute a command containing detected signature strings by passing it to PowerShell as a Base64-encoded blob. The raw script content never appears in the file on disk.

## Scanner Behavior

The file-based scanner reads raw bytes from files on disk and matches against known signature patterns. If it finds strings like `malware`, `virus`, or `Invoke-Mimikatz` as contiguous byte sequences in a file, it flags the file.

AMSI, on the other hand, scans content at execution time. However, when PowerShell receives an encoded command via its `-EncodedCommand` parameter, the decoding happens internally within the powershell.exe process. The file on disk (a .bat file, shortcut, or script that launches PowerShell) only contains the Base64 string — which looks nothing like the original payload.

**Note:** This bypass is primarily effective against file-based static scanning. Modern AMSI implementations will still see the decoded content when it executes. This challenge focuses on evading the file scanner.

## Rules

- The file you create on disk must not contain any detected signature strings in plaintext.
- The command must execute successfully and produce the expected output (e.g., print a detected keyword).
- You must use PowerShell's built-in encoding mechanism.

## Hints

1. `powershell.exe -EncodedCommand <base64string>` accepts a Base64-encoded command.
2. The encoding must be **UTF-16LE** (Unicode) before Base64 encoding — this is PowerShell's expected format.
3. In PowerShell, you can encode like this: `[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("your command"))`.
4. The resulting Base64 string bears no visual resemblance to the original command — no signature match is possible on the encoded form.

---

[View Solution](../solutions/34-base64-encoded-command.md)
