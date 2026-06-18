---
title: "Challenge 25: Right-to-Left Override (RTLO) Attack"
challenge_number: 25
difficulty: hard
category: "Extension Heuristic Bypass"
permalink: /challenges/25-rtlo-unicode/
---

# Challenge 25: Right-to-Left Override (RTLO) Attack

**Difficulty:** Hard  
**Category:** Extension Heuristic Bypass

## Objective

Unicode includes directional formatting characters that control how text is **displayed** without changing the underlying bytes. Your goal is to craft a filename that:

1. Has a truly malicious extension (which the scanner may warn on).
2. Appears visually to have a completely harmless extension when displayed in file managers, email clients, or chat applications.

The scanner only warns and never blocks, so even if the real extension triggers a warning, the social engineering aspect makes this technique devastating in practice.

## Scanner Behavior

- The scanner performs a byte-level `rfind('.')` on the raw filename string.
- It extracts and checks the extension based on the actual bytes, not the visual rendering.
- Unicode directional override characters are not stripped or normalized before analysis.
- The scanner issues a warning if the real extension matches the suspicious list, but the file is never blocked.

## Hints

1. U+202E is the Right-to-Left Override (RLO) character. All text following it is rendered in reverse order visually.
2. Consider what `invoice_\u202Efdp.exe` looks like when rendered: the characters after RLO (`fdp.exe`) are displayed reversed as `exe.pdf`.
3. Most file managers and UI elements will render the RLO character, making the filename appear completely different from its actual bytes.
4. The technique requires careful placement of the RLO character to produce a convincing visual result.

---

[View Solution](../solutions/25-rtlo-unicode.md)
