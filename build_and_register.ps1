# build_and_register.ps1
# Complete workflow to build and register the AMSI provider
#
# Usage:
#   .\build_and_register.ps1 -Build           # Just build the DLL
#   .\build_and_register.ps1 -BuildAndRegister # Build and register (requires Admin)
#   .\build_and_register.ps1 -Status          # Show current status
#   .\build_and_register.ps1 -Unregister      # Unregister the provider

param(
    [switch]$Build,
    [switch]$BuildAndRegister,
    [switch]$Status,
    [switch]$Unregister
)

$PROVIDER_GUID = "{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}"
$PROVIDER_NAME = "MostShittyAVProvider"
$DLL_NAME = "MostShittyAVWrapper.dll"
$SOURCE_FILE = "nim_amsi_wrapper_dll.nim"

function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Build-DLL {
    Write-Host "`n=== Building AMSI Provider DLL ===" -ForegroundColor Cyan
    
    # Remove old DLL if it exists
    if (Test-Path $DLL_NAME) {
        Write-Host "Removing old DLL..." -ForegroundColor Yellow
        try {
            Remove-Item $DLL_NAME -Force -ErrorAction Stop
        } catch {
            Write-Host "Warning: Could not remove old DLL (may be in use)" -ForegroundColor Yellow
            $oldName = "$DLL_NAME.old"
            Move-Item $DLL_NAME $oldName -Force
            Write-Host "Renamed to $oldName" -ForegroundColor Yellow
        }
    }
    
    # Build with Nim
    Write-Host "Compiling $SOURCE_FILE..." -ForegroundColor Cyan
    $buildCmd = "nim c --app:lib --cpu:amd64 --out:$DLL_NAME $SOURCE_FILE"
    
    Write-Host "Command: $buildCmd" -ForegroundColor Gray
    Invoke-Expression $buildCmd
    
    if ($LASTEXITCODE -eq 0 -and (Test-Path $DLL_NAME)) {
        Write-Host "`n✓ Build successful!" -ForegroundColor Green
        Write-Host "  DLL: $((Get-Item $DLL_NAME).FullName)" -ForegroundColor Gray
        Write-Host "  Size: $([math]::Round((Get-Item $DLL_NAME).Length / 1KB, 2)) KB" -ForegroundColor Gray
        return $true
    } else {
        Write-Host "`n✗ Build failed!" -ForegroundColor Red
        return $false
    }
}

function Register-Provider {
    if (-not (Test-IsAdmin)) {
        Write-Host "`n✗ ERROR: Administrator privileges required!" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
        return $false
    }
    
    if (-not (Test-Path $DLL_NAME)) {
        Write-Host "`n✗ ERROR: DLL not found: $DLL_NAME" -ForegroundColor Red
        Write-Host "Build the DLL first with: .\build_and_register.ps1 -Build" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "`n=== Registering AMSI Provider ===" -ForegroundColor Cyan
    Write-Host "DLL: $((Get-Item $DLL_NAME).FullName)" -ForegroundColor Gray
    
    # Use regsvr32 to register
    $dllPath = (Get-Item $DLL_NAME).FullName
    Write-Host "Running: regsvr32 /s `"$dllPath`"" -ForegroundColor Gray
    
    $result = Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s `"$dllPath`"" -Wait -PassThru -NoNewWindow
    
    if ($result.ExitCode -eq 0) {
        Write-Host "✓ regsvr32 completed successfully!" -ForegroundColor Green
        
        # Verify registration
        Start-Sleep -Milliseconds 500
        $amsiKey = "HKLM:\SOFTWARE\Microsoft\AMSI\Providers\$PROVIDER_GUID"
        if (Test-Path $amsiKey) {
            Write-Host "✓ AMSI Provider registered successfully!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "⚠ Warning: regsvr32 succeeded but registry keys not found" -ForegroundColor Yellow
            Write-Host "  The DllRegisterServer function may have returned an error" -ForegroundColor Gray
            return $false
        }
    } else {
        Write-Host "✗ Registration failed with exit code: $($result.ExitCode)" -ForegroundColor Red
        switch ($result.ExitCode) {
            3 { Write-Host "  DllRegisterServer entry point not found" -ForegroundColor Yellow }
            4 { Write-Host "  DllRegisterServer failed (check permissions)" -ForegroundColor Yellow }
            5 { Write-Host "  Access denied (run as Administrator)" -ForegroundColor Yellow }
            default { Write-Host "  Unknown error code" -ForegroundColor Yellow }
        }
        return $false
    }
}

function Unregister-Provider {
    if (-not (Test-IsAdmin)) {
        Write-Host "`n✗ ERROR: Administrator privileges required!" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "`n=== Unregistering AMSI Provider ===" -ForegroundColor Cyan
    
    if (Test-Path $DLL_NAME) {
        $dllPath = (Get-Item $DLL_NAME).FullName
        Write-Host "Running: regsvr32 /u /s `"$dllPath`"" -ForegroundColor Gray
        $result = Start-Process -FilePath "regsvr32.exe" -ArgumentList "/u /s `"$dllPath`"" -Wait -PassThru -NoNewWindow
        
        if ($result.ExitCode -eq 0) {
            Write-Host "✓ regsvr32 unregister completed" -ForegroundColor Green
        }
    } else {
        Write-Host "Warning: DLL not found, will clean registry manually" -ForegroundColor Yellow
    }
    
    # Manual cleanup
    Write-Host "Cleaning up registry keys..." -ForegroundColor Cyan
    
    $amsiKey = "HKLM:\SOFTWARE\Microsoft\AMSI\Providers\$PROVIDER_GUID"
    if (Test-Path $amsiKey) {
        Remove-Item -Path $amsiKey -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Removed AMSI Provider key" -ForegroundColor Green
    }
    
    $inprocKey = "HKLM:\SOFTWARE\Classes\CLSID\$PROVIDER_GUID\InprocServer32"
    if (Test-Path $inprocKey) {
        Remove-Item -Path $inprocKey -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Removed InprocServer32 key" -ForegroundColor Green
    }
    
    $clsidKey = "HKLM:\SOFTWARE\Classes\CLSID\$PROVIDER_GUID"
    if (Test-Path $clsidKey) {
        Remove-Item -Path $clsidKey -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Removed CLSID key" -ForegroundColor Green
    }
    
    Write-Host "`n✓ Unregistration complete!" -ForegroundColor Green
    return $true
}

function Show-Status {
    Write-Host "`n=== AMSI Provider Status ===" -ForegroundColor Cyan
    Write-Host "Provider GUID: $PROVIDER_GUID" -ForegroundColor Gray
    Write-Host "Provider Name: $PROVIDER_NAME" -ForegroundColor Gray
    Write-Host "DLL Path: $PSScriptRoot\$DLL_NAME" -ForegroundColor Gray
    
    if (Test-Path $DLL_NAME) {
        $dll = Get-Item $DLL_NAME
        Write-Host "DLL Exists: YES ($([math]::Round($dll.Length / 1KB, 2)) KB)" -ForegroundColor Green
        Write-Host "Last Modified: $($dll.LastWriteTime)" -ForegroundColor Gray
    } else {
        Write-Host "DLL Exists: NO" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Check AMSI registration
    $amsiKey = "HKLM:\SOFTWARE\Microsoft\AMSI\Providers\$PROVIDER_GUID"
    $amsiExists = Test-Path $amsiKey
    Write-Host "AMSI Registration: " -NoNewline
    if ($amsiExists) {
        Write-Host "REGISTERED ✓" -ForegroundColor Green
        try {
            $value = Get-ItemProperty -Path $amsiKey -Name "(default)" -ErrorAction SilentlyContinue
            if ($value) {
                Write-Host "  Provider Name: $($value.'(default)')" -ForegroundColor Gray
            }
        } catch {}
    } else {
        Write-Host "NOT REGISTERED" -ForegroundColor Yellow
    }
    
    # Check COM registration
    $clsidKey = "HKLM:\SOFTWARE\Classes\CLSID\$PROVIDER_GUID"
    $clsidExists = Test-Path $clsidKey
    Write-Host "COM CLSID: " -NoNewline
    if ($clsidExists) {
        Write-Host "REGISTERED ✓" -ForegroundColor Green
        $inprocKey = "$clsidKey\InprocServer32"
        if (Test-Path $inprocKey) {
            try {
                $dllPath = Get-ItemProperty -Path $inprocKey -Name "(default)" -ErrorAction SilentlyContinue
                if ($dllPath) {
                    Write-Host "  DLL Path: $($dllPath.'(default)')" -ForegroundColor Gray
                }
                $threading = Get-ItemProperty -Path $inprocKey -Name "ThreadingModel" -ErrorAction SilentlyContinue
                if ($threading) {
                    Write-Host "  Threading: $($threading.ThreadingModel)" -ForegroundColor Gray
                }
            } catch {}
        }
    } else {
        Write-Host "NOT REGISTERED" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    if ($amsiExists -and $clsidExists) {
        Write-Host "Status: ACTIVE - AMSI will load this provider ✓" -ForegroundColor Green
    } elseif ($amsiExists -or $clsidExists) {
        Write-Host "Status: PARTIAL - Some keys registered" -ForegroundColor Yellow
    } else {
        Write-Host "Status: NOT ACTIVE - Provider not registered" -ForegroundColor Gray
    }
    
    Write-Host ""
}

# Main script logic
if ($BuildAndRegister) {
    Write-Host "=== Build and Register Workflow ===" -ForegroundColor Magenta
    
    if (Build-DLL) {
        if (Register-Provider) {
            Write-Host "`n=== SUCCESS ===" -ForegroundColor Green
            Write-Host "AMSI Provider is built and registered!" -ForegroundColor Green
            Show-Status
            Write-Host "`nIMPORTANT: Restart applications for them to load the provider." -ForegroundColor Yellow
            Write-Host "Example: Start a new PowerShell window" -ForegroundColor Gray
        } else {
            Write-Host "`n=== PARTIAL SUCCESS ===" -ForegroundColor Yellow
            Write-Host "Build succeeded but registration failed." -ForegroundColor Yellow
            Write-Host "Make sure you're running as Administrator." -ForegroundColor Gray
        }
    } else {
        Write-Host "`n=== FAILED ===" -ForegroundColor Red
        Write-Host "Build failed. Fix compilation errors and try again." -ForegroundColor Red
    }
} elseif ($Build) {
    Build-DLL | Out-Null
    if (Test-Path $DLL_NAME) {
        Show-Status
    }
} elseif ($Unregister) {
    Unregister-Provider | Out-Null
    Show-Status
} elseif ($Status) {
    Show-Status
} else {
    Write-Host @"

===============================================================
         MostShittyAV - AMSI Provider Build Tool
===============================================================

Usage:
  .\build_and_register.ps1 -Build
      Build the AMSI provider DLL

  .\build_and_register.ps1 -BuildAndRegister
      Build and register the AMSI provider (requires Admin)

  .\build_and_register.ps1 -Status
      Show current build and registration status

  .\build_and_register.ps1 -Unregister
      Unregister the AMSI provider (requires Admin)

Quick Start:
  1. Build: .\build_and_register.ps1 -Build
  2. Check: .\build_and_register.ps1 -Status
  3. Register (as Admin): .\build_and_register.ps1 -BuildAndRegister

Provider Details:
  GUID: $PROVIDER_GUID
  Name: $PROVIDER_NAME
  DLL:  $DLL_NAME

"@
    Show-Status
}
