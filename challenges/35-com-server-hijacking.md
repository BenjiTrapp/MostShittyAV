---
title: "Challenge 35: COM Server Hijacking"
challenge_number: 35
difficulty: hard
category: "AMSI Bypass"
permalink: /challenges/35-com-server-hijacking/
---

# Challenge 35: COM Server Hijacking

**Difficulty:** Hard  
**Category:** AMSI Bypass

---

## Objective

Redirect AMSI to load a dummy provider by hijacking the COM server registration in the Windows registry. After your modification, AMSI calls will resolve to a harmless DLL instead of the real antimalware provider.

## Scanner Behavior

AMSI providers are registered as COM (Component Object Model) servers. When amsi.dll initializes, it enumerates providers listed under:

```
HKLM\SOFTWARE\Microsoft\AMSI\Providers\{CLSID}
```

For each provider CLSID, Windows uses standard COM resolution to locate the DLL. COM resolution follows a specific search order:

1. **HKCU\Software\Classes\CLSID\{...}\InprocServer32** (per-user, checked first)
2. HKLM\Software\Classes\CLSID\{...}\InprocServer32 (machine-wide)

Because HKCU is checked **before** HKLM, any user can override where a COM server points — without administrator privileges.

Our AMSI provider (`nim_amsi_wrapper_dll`) is registered at the machine level. If you create a matching HKCU entry pointing to a different DLL, AMSI will load your DLL instead.

## Rules

- You must redirect the AMSI provider COM registration to a non-functional DLL.
- After hijacking, AMSI scans must either not detect signatures or fail silently.
- You may not modify HKLM (no admin rights required for this bypass).
- You must not crash the host process.

## Hints

1. First, find the CLSID of the registered AMSI provider under `HKLM\SOFTWARE\Microsoft\AMSI\Providers\`.
2. Create the equivalent key path under HKCU: `HKCU\Software\Classes\CLSID\{same-CLSID}\InprocServer32`.
3. Point `InprocServer32` to a DLL that exports the required COM interfaces but does nothing (or to a non-existent path — AMSI will fail to load and silently continue).
4. The change takes effect for new processes — existing PowerShell sessions retain the old provider.
5. A minimal dummy DLL just needs to export `DllGetClassObject` or even pointing to a non-existent path may suffice.

---

[View Solution](../solutions/35-com-server-hijacking.md)
