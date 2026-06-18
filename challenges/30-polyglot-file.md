---
title: "Challenge 30: Polyglot File Exploitation"
challenge_number: 30
difficulty: hard
category: "Extension Heuristic Bypass"
permalink: /challenges/30-polyglot-file/
---

# Challenge 30: Polyglot File Exploitation

**Difficulty:** Hard  
**Category:** Extension Heuristic Bypass

## Objective

The scanner determines file type **solely** by extension and never inspects content or magic bytes. A polyglot file is a single file that is simultaneously valid in multiple formats. Your goal is to create a file that:

1. Has an innocuous extension (e.g., `.pdf`, `.png`, `.jpg`) that is not on the suspicious list.
2. Is actually valid and functional in that claimed format (opens correctly in the expected application).
3. Also contains executable code that can be triggered through an alternate interpretation of the same bytes.

## Scanner Behavior

- File type is determined exclusively by the file extension.
- No magic byte validation is performed (the scanner never checks `%PDF`, `\x89PNG`, `MZ`, etc.).
- Content scanning only looks for specific string signatures - it does not understand file format structure.
- A `.pdf` file is treated as a PDF regardless of what bytes it actually contains.
- The scanner will not warn on non-suspicious extensions, even if the file content is clearly executable.

## Hints

1. Many file formats are flexible about what data can appear in certain regions of the file (comments, metadata, padding).
2. Some formats (like PDF) can contain embedded JavaScript that executes when the file is opened.
3. A file can have valid image headers while containing HTML/JavaScript after the image data, exploitable in certain contexts.
4. Consider formats where executable content can be embedded within valid structural elements: ZIP archives (which are also valid .jar/.docx), PDFs with JavaScript actions, or images with trailing script data.
5. The key insight: the scanner trusts the extension completely and never validates that content matches the claimed type.

---

[View Solution](../solutions/30-polyglot-file.md)
