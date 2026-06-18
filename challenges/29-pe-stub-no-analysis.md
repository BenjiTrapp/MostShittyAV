---
title: "Challenge 29: Minimal PE with No Structural Analysis"
challenge_number: 29
difficulty: hard
category: "Extension Heuristic Bypass"
permalink: /challenges/29-pe-stub-no-analysis/
---

# Challenge 29: Minimal PE with No Structural Analysis

**Difficulty:** Hard  
**Category:** Extension Heuristic Bypass

## Objective

The scanner performs **zero** structural analysis of PE (Portable Executable) files. It does not parse MZ headers, PE signatures, section tables, import directories, or measure section entropy. Your goal is to create a minimal, fully functional PE executable that passes all scanner checks without triggering any alerts beyond the extension warning.

## Scanner Behavior

- The scanner checks the file extension (`.exe` will trigger a warning, but never a block).
- No binary analysis is performed: the scanner does not read or validate file content structure.
- MZ magic bytes (`4D 5A`) are not checked.
- PE signature (`50 45 00 00`) is not checked.
- Import tables, section headers, and entry points are not examined.
- Section entropy (a common indicator of packing/encryption) is not calculated.
- String scanning is the only content-based check, and it looks for specific signature patterns.

## Hints

1. A valid PE executable only needs the correct bytes in the correct offsets - the DOS header, PE header, and at least one section.
2. The smallest valid PE that Windows will execute can be remarkably small (a few hundred bytes).
3. Since the scanner only does string matching on content, avoid known signature strings and your PE passes cleanly.
4. The extension warning for `.exe` is cosmetic only - consider combining this with other extension bypass techniques for zero alerts.

---

[View Solution](../solutions/29-pe-stub-no-analysis.md)
