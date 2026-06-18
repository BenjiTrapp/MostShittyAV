---
title: "Challenge 24: Double Extension Deception"
challenge_number: 24
difficulty: easy
category: "Extension Heuristic Bypass"
permalink: /challenges/24-double-extension/
---

# Challenge 24: Double Extension Deception

**Difficulty:** Easy  
**Category:** Extension Heuristic Bypass

## Objective

Files can contain multiple dots in their name. The scanner only examines the **last** extension (everything after the final dot). Your goal is to create a socially-engineered filename that:

1. Appears harmless to a human user viewing it in Windows Explorer.
2. Is actually executable by Windows.
3. Triggers only a warning (never a block) from the scanner.

## Scanner Behavior

- The scanner uses `rfind('.')` to find the last dot in the filename.
- Only the substring after that final dot is checked against the suspicious list.
- The scanner issues a warning if the last extension matches, but **never blocks** the file.
- No analysis is performed on any earlier extensions in the filename.
- The filename's visual appearance to the user is not considered.

## Hints

1. Windows Explorer hides "known file extensions" by default in most configurations.
2. When extensions are hidden, `report.pdf.exe` appears to the user as simply `report.pdf`.
3. The scanner will still warn on `.exe`, but remember: warnings don't block anything.
4. Consider combining this with long filenames or excessive spaces to push the real extension off-screen.

---

[View Solution](../solutions/24-double-extension.md)
