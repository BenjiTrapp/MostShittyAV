# build_amsi_demo.ps1
# Build and register the Nim AMSI Demo Provider

param(
    [switch]$Build,
    [switch]$Register,
    [switch]$Unregister,
    [switch]$BuildAndRegister,
    [switch]$Status
)

$PROVIDER_GUID = "{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}"
$DLL_NAME = "NimAmsiDemo.dll"
$SOURCE_FILE = "amsi_demo_provider.nim"

function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Build-DLL {
    Write-Host "`n=== Building AMSI Demo Provider ===" -ForegroundColor Cyan
    
    if (Test-Path $DLL_NAME) {
        Write-Host "Removing old DLL..." -ForegroundColor Yellow
        Remove-Item $DLL_NAME -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "Compiling $SOURCE_FILE..." -ForegroundColor Cyan
    $buildCmd = "nim c --app:lib --cpu:amd64 --mm:orc -d:release --out:$DLL_NAME $SOURCE_FILE"
    
    Write-Host "Command: $buildCmd" -ForegroundColor Gray
    Invoke-Expression $buildCmd
    
    if ($LASTEXITCODE -eq 0 -and (Test-Path $DLL_NAME)) {
        Write-Host "`n✓ Build successful!" -ForegroundColor Green
        $dll = Get-Item $DLL_NAME
        Write-Host "  DLL: $($dll.FullName)" -ForegroundColor Gray
        Write-Host "  Size: $([math]::Round($dll.Length / 1KB, 2)) KB" -ForegroundColor Gray
        return $true
    } else {
        Write-Host "`n✗ Build failed!" -ForegroundColor Red
        return $false
    }
}

function Register-Provider {
    if (-not (Test-IsAdmin)) {
        Write-Host "`n✗ ERROR: Administrator privileges required!" -ForegroundColor Red
        return $false
    }
    
    if (-not (Test-Path $DLL_NAME)) {
        Write-Host "`n✗ ERROR: DLL not found: $DLL_NAME" -ForegroundColor Red
        return $false
    }
    
    Write-Host "`n=== Registering AMSI Provider ===" -ForegroundColor Cyan
    $dllPath = (Get-Item $DLL_NAME).FullName
    Write-Host "Running: regsvr32 /s `"$dllPath`"" -ForegroundColor Gray
    
    $result = Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s `"$dllPath`"" -Wait -PassThru -NoNewWindow
    
    if ($result.ExitCode -eq 0) {
        Write-Host "✓ Registration completed!" -ForegroundColor Green
        Start-Sleep -Milliseconds 500
        
        $amsiKey = "HKLM:\SOFTWARE\Microsoft\AMSI\Providers\$PROVIDER_GUID"
        if (Test-Path $amsiKey) {
            Write-Host "✓ AMSI Provider registered successfully!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "⚠ Warning: Registry keys not found" -ForegroundColor Yellow
            return $false
        }
    } else {
        Write-Host "✗ Registration failed with exit code: $($result.ExitCode)" -ForegroundColor Red
        return $false
    }
}

function Unregister-Provider {
    if (-not (Test-IsAdmin)) {
        Write-Host "`n✗ ERROR: Administrator privileges required!" -ForegroundColor Red
        return $false
    }
    
    Write-Host "`n=== Unregistering AMSI Provider ===" -ForegroundColor Cyan
    
    if (Test-Path $DLL_NAME) {
        $dllPath = (Get-Item $DLL_NAME).FullName
        Write-Host "Running: regsvr32 /u /s `"$dllPath`"" -ForegroundColor Gray
        Start-Process -FilePath "regsvr32.exe" -ArgumentList "/u /s `"$dllPath`"" -Wait -NoNewWindow
    }
    
    # Manual cleanup
    $amsiKey = "HKLM:\SOFTWARE\Microsoft\AMSI\Providers\$PROVIDER_GUID"
    if (Test-Path $amsiKey) {
        Remove-Item -Path $amsiKey -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Removed AMSI Provider key" -ForegroundColor Green
    }
    
    $clsidKey = "HKLM:\SOFTWARE\Classes\CLSID\$PROVIDER_GUID"
    if (Test-Path $clsidKey) {
        Remove-Item -Path $clsidKey -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Removed CLSID keys" -ForegroundColor Green
    }
    
    Write-Host "`n✓ Unregistration complete!" -ForegroundColor Green
    return $true
}

function Show-Status {
    Write-Host "`n=== AMSI Demo Provider Status ===" -ForegroundColor Cyan
    Write-Host "Provider GUID: $PROVIDER_GUID" -ForegroundColor Gray
    Write-Host "DLL Name: $DLL_NAME" -ForegroundColor Gray
    
    if (Test-Path $DLL_NAME) {
        $dll = Get-Item $DLL_NAME
        Write-Host "`nDLL: EXISTS ✓" -ForegroundColor Green
        Write-Host "  Path: $($dll.FullName)" -ForegroundColor Gray
        Write-Host "  Size: $([math]::Round($dll.Length / 1KB, 2)) KB" -ForegroundColor Gray
        Write-Host "  Modified: $($dll.LastWriteTime)" -ForegroundColor Gray
    } else {
        Write-Host "`nDLL: NOT FOUND" -ForegroundColor Red
    }
    
    $amsiKey = "HKLM:\SOFTWARE\Microsoft\AMSI\Providers\$PROVIDER_GUID"
    Write-Host "`nAMSI Registration: " -NoNewline
    if (Test-Path $amsiKey) {
        Write-Host "REGISTERED ✓" -ForegroundColor Green
    } else {
        Write-Host "NOT REGISTERED" -ForegroundColor Yellow
    }
    
    $clsidKey = "HKLM:\SOFTWARE\Classes\CLSID\$PROVIDER_GUID"
    Write-Host "COM CLSID: " -NoNewline
    if (Test-Path $clsidKey) {
        Write-Host "REGISTERED ✓" -ForegroundColor Green
    } else {
        Write-Host "NOT REGISTERED" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Main execution
if ($BuildAndRegister) {
    if (Build-DLL) {
        if (Register-Provider) {
            Write-Host "`n=== SUCCESS ===" -ForegroundColor Green
            Show-Status
            Write-Host "`nIMPORTANT: Start a NEW PowerShell window to test the provider!" -ForegroundColor Yellow
        }
    }
} elseif ($Build) {
    Build-DLL
    Show-Status
} elseif ($Register) {
    Register-Provider
    Show-Status
} elseif ($Unregister) {
    Unregister-Provider
    Show-Status
} elseif ($Status) {
    Show-Status
} else {
    Write-Host @"

=================================================================
           Nim AMSI Demo Provider - Build Tool
=================================================================

Usage:
  .\build_amsi_demo.ps1 -Build
      Build the DLL only

  .\build_amsi_demo.ps1 -BuildAndRegister
      Build and register (requires Admin)

  .\build_amsi_demo.ps1 -Register
      Register existing DLL (requires Admin)

  .\build_amsi_demo.ps1 -Unregister
      Unregister the provider (requires Admin)

  .\build_amsi_demo.ps1 -Status
      Show current status

Provider Details:
  GUID: $PROVIDER_GUID
  DLL:  $DLL_NAME

"@
    Show-Status
}
