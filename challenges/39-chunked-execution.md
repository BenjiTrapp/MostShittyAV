---
title: "Challenge 39: Chunked Execution"
challenge_number: 39
difficulty: medium
category: "AMSI Bypass"
permalink: /challenges/39-chunked-execution/
---

# Challenge 39: Chunked Execution

**Difficulty:** Medium  
**Category:** AMSI Bypass

---

## Objective

Execute a payload that would normally be detected by AMSI, by splitting it across multiple independent script blocks so that no single scan buffer contains the complete malicious content.

## Scanner Behavior

AMSI scans content in discrete units. In PowerShell, each of the following is scanned as a separate buffer:

- Individual commands typed at the prompt
- Script blocks (`{ ... }`)
- Scripts loaded via `. .\script.ps1` or `& .\script.ps1`
- Modules loaded via `Import-Module`

The AMSI provider (`nim_amsi_wrapper_dll`) evaluates each buffer **independently**. It has no cross-buffer memory or correlation. If a signature like `Invoke-Mimikatz` appears split across two separate buffers, neither buffer triggers detection on its own.

This is a fundamental limitation: AMSI is stateless between scans. It sees snapshots, not the full execution timeline.

## Rules

- Your final payload must produce the same effect as if you had typed the detected string in one command.
- No single AMSI scan buffer may contain a complete detected signature.
- Each individual fragment must pass AMSI scanning without detection.
- The final assembly and execution must happen in a way that avoids scanning of the complete payload.

## Hints

1. Define partial strings or functions across multiple separate commands. Each command is scanned independently.
2. Variables persist across scan boundaries — set up pieces in earlier commands, combine them in a later one.
3. Consider building a function name character by character, then invoking it via `& $variable`.
4. The `Invoke-Expression` cmdlet can execute dynamically assembled strings, but be aware it triggers its own AMSI scan of the content.
5. Think carefully about which operations trigger new scans and which just use previously stored data.

---

[View Solution](../solutions/39-chunked-execution.md)
