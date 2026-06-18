---
title: "Challenge 21: Extension Avoidance (Small Executable)"
challenge_number: 21
difficulty: easy
category: "Small Executable Bypass"
permalink: /challenges/21-extension-avoidance-small/
---

# Challenge 21: Extension Avoidance (Small Executable)

**Difficulty:** Easy  
**Category:** Small Executable Bypass

---

## Objective

The small executable check requires **both** conditions to be true: the file must be under 32 bytes AND have a suspicious extension. Bypass the check by breaking one of these conditions — specifically, use an extension that isn't in the suspicious list while keeping the file small and still executable.

## Scanner Behavior

The scanner's small executable check evaluates two conditions:

1. **Size condition:** File is less than 32 bytes.
2. **Extension condition:** File extension matches a list of known suspicious/executable extensions.

The suspicious extension list includes common executable formats:
`.exe`, `.bat`, `.cmd`, `.ps1`, `.vbs`, `.scr`, `.com`, `.js`, `.wsf`, `.hta`

**Both conditions must be true** for the check to trigger. If either condition is false, the file passes this check.

The scanner does not verify whether a file's content matches its extension. It treats the extension as a simple string comparison.

## Rules

- Your file must be **less than 32 bytes** in total size.
- Your file must NOT use any extension from the suspicious list.
- The file must still be **executable** on the target system (Windows) — it should run and perform an action when invoked appropriately.
- Demonstrate that the scanner's small executable check does not trigger.

## Hints

1. What if the extension isn't in the suspicious list? Does the file still execute?
2. Not all executable file associations are in the scanner's list. Are there others that Windows will run?
3. Think about how Windows determines what to do with a file — it's not just about the extensions the scanner knows about.
4. Some extensions can be configured, aliased, or associated with interpreters that the scanner doesn't track.

---

[View Solution](../solutions/21-extension-avoidance-small.md)
