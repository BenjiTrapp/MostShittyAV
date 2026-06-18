---
title: "Challenge 38: AMSI Context Corruption"
challenge_number: 38
difficulty: medium
category: "AMSI Bypass"
permalink: /challenges/38-context-corruption/
---

# Challenge 38: AMSI Context Corruption

**Difficulty:** Medium  
**Category:** AMSI Bypass

---

## Objective

Corrupt the AMSI context handle used by PowerShell so that subsequent calls to `AmsiScanBuffer` fail gracefully. When AMSI cannot scan, PowerShell defaults to allowing execution.

## Scanner Behavior

AMSI maintains state through opaque context handles. When PowerShell initializes AMSI, it calls `AmsiInitialize`, which returns an `amsiContext` handle. This handle is then passed to every subsequent `AmsiScanBuffer` call to identify the scanning session.

The scan flow works like this:

1. PowerShell stores the `amsiContext` handle internally
2. For each scan, PowerShell calls `AmsiScanBuffer(amsiContext, buffer, ...)`
3. amsi.dll validates the context handle
4. If valid, the buffer is forwarded to providers (our `nim_amsi_wrapper_dll`)
5. The result is returned to PowerShell

If the context handle is **invalid** (null, corrupted, or zeroed out), `AmsiScanBuffer` returns an error code. PowerShell's error handling interprets scan failures as **non-malicious** — it continues execution rather than blocking. This is a fail-open design.

## Rules

- You must corrupt or nullify the AMSI context handle stored by PowerShell.
- After corruption, AMSI scans must fail, and PowerShell must allow execution to continue.
- You may not patch amsi.dll in memory.
- You may not use the `amsiInitFailed` flag (that's Challenge 31).

## Hints

1. The context handle is stored as a field in the same utility class referenced in Challenge 31.
2. `IntPtr.Zero` is an invalid handle value — overwriting the context with this value will cause all future scans to fail.
3. You need Reflection to access the private field that stores the context.
4. The field name relates to the AMSI context or session.

---

[View Solution](../solutions/38-context-corruption.md)
