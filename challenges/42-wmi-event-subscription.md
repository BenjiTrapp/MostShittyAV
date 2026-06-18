---
title: "Challenge 42: WMI Event Subscription"
challenge_number: 42
difficulty: hard
category: "AMSI Bypass"
permalink: /challenges/42-wmi-event-subscription/
---

# Challenge 42: WMI Event Subscription

**Difficulty:** Hard  
**Category:** AMSI Bypass

---

## Objective

Execute a malicious payload in a process that has its own independent AMSI context (or none at all) by leveraging WMI event subscriptions. Your payload runs in `wmiprvse.exe`, completely outside your PowerShell session's AMSI hooks.

## Scanner Behavior

AMSI hooks are **per-process**. Each process that initializes AMSI gets its own context, and scanning occurs within that process's space. Importantly:

- Your PowerShell session has AMSI initialized and actively scanning
- Other processes on the system may not have AMSI initialized
- Even if another process has AMSI, it is a completely separate context with no awareness of your session

WMI (Windows Management Instrumentation) event subscriptions allow you to define actions that execute when certain system events occur. These actions run inside the `wmiprvse.exe` (WMI Provider Host) process, which is a separate process from your PowerShell session.

The key insight: code executed via WMI runs in a different process context where your session's AMSI provider may not be active, or where the scanning context is independent.

## Rules

- You must execute a payload containing a detected signature string via WMI.
- The execution must happen outside your current PowerShell process.
- You may only use built-in Windows components (Living off the Land).
- No external tools or downloads.

## Hints

1. `Register-WmiEvent` or the `__EventFilter` / `__EventConsumer` WMI classes allow you to set up event-triggered execution.
2. `CommandLineEventConsumer` executes arbitrary commands when an event fires.
3. You can create an event that triggers immediately (e.g., on a timer with a 1-second interval).
4. The payload executes as SYSTEM in `wmiprvse.exe` — a completely different process from your shell.
5. This is a classic "Living off the Land" technique using only built-in Windows management infrastructure.

---

[View Solution](../solutions/42-wmi-event-subscription.md)
