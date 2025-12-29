# complete_amsi_cleanup.ps1
# Complete AMSI provider cleanup and reset
# RUN AS ADMINISTRATOR

param(
    [switch]$KeepNimProvider
)

$ErrorActionPreference = "Continue"

# Check admin
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`nERROR: Must run as Administrator!" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== AMSI Provider Complete Cleanup ===" -ForegroundColor Cyan

# Known provider GUIDs
$nimProviderGUID = "{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}"
$oldProviderGUID = "{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}"
$defenderGUID = "{2781761E-28E0-4109-99FE-B9D127C57AFE}"

# Get all registered providers
Write-Host "`nStep 1: Scanning registered AMSI providers..." -ForegroundColor Yellow
$providersPath = "HKLM:\SOFTWARE\Microsoft\AMSI\Providers"
$providers = @()

if (Test-Path $providersPath) {
    $providers = Get-ChildItem $providersPath | ForEach-Object {
        $guid = $_.PSChildName
        $name = (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).'(default)'
        
        # Check DLL existence
        $clsidPath = "HKLM:\SOFTWARE\Classes\CLSID\$guid\InprocServer32"
        $dllExists = $false
        $dllPath = ""
        
        if (Test-Path $clsidPath) {
            $dllPath = (Get-ItemProperty -Path $clsidPath -ErrorAction SilentlyContinue).'(default)'
            if ($dllPath) {
                $dllPath = $dllPath.Trim('"')
                $dllExists = Test-Path $dllPath
            }
        }
        
        [PSCustomObject]@{
            GUID = $guid
            Name = $name
            DLLPath = $dllPath
            DLLExists = $dllExists
        }
    }
}

# Display current state
Write-Host "`nCurrent providers:" -ForegroundColor Cyan
foreach ($p in $providers) {
    Write-Host "  GUID: $($p.GUID)" -ForegroundColor Gray
    Write-Host "  Name: $($p.Name)" -ForegroundColor Gray
    Write-Host "  DLL:  $($p.DLLPath)" -ForegroundColor Gray
    if ($p.DLLExists) {
        Write-Host "  Status: OK" -ForegroundColor Green
    } else {
        Write-Host "  Status: BROKEN (DLL missing)" -ForegroundColor Red
    }
    Write-Host ""
}

# Remove all providers except Nim if requested
Write-Host "`nStep 2: Removing providers..." -ForegroundColor Yellow

foreach ($p in $providers) {
    $shouldRemove = $false
    
    if ($KeepNimProvider -and $p.GUID -eq $nimProviderGUID) {
        Write-Host "  Keeping Nim provider: $($p.Name)" -ForegroundColor Green
        continue
    }
    
    if (-not $p.DLLExists) {
        Write-Host "  Removing broken provider: $($p.Name) ($($p.GUID))" -ForegroundColor Yellow
        $shouldRemove = $true
    } elseif ($p.GUID -eq $oldProviderGUID) {
        Write-Host "  Removing old MostShittyAV provider: $($p.GUID)" -ForegroundColor Yellow
        $shouldRemove = $true
    } elseif (-not $KeepNimProvider -and $p.GUID -eq $nimProviderGUID) {
        Write-Host "  Removing Nim provider: $($p.Name)" -ForegroundColor Yellow
        $shouldRemove = $true
    }
    
    if ($shouldRemove) {
        try {
            Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\AMSI\Providers\$($p.GUID)" -Recurse -Force -ErrorAction Stop
            Write-Host "    ✓ Removed from AMSI registry" -ForegroundColor Green
        } catch {
            Write-Host "    ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        try {
            Remove-Item -Path "HKLM:\SOFTWARE\Classes\CLSID\$($p.GUID)" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "    ✓ Removed CLSID" -ForegroundColor Green
        } catch {
            Write-Host "    ⚠ CLSID not removed" -ForegroundColor Gray
        }
    }
}

# Final verification
Write-Host "`nStep 3: Final verification..." -ForegroundColor Yellow
$remainingProviders = Get-ChildItem $providersPath -ErrorAction SilentlyContinue

if (-not $remainingProviders) {
    Write-Host "  ⚠ NO AMSI providers registered (AMSI disabled!)" -ForegroundColor Yellow
} else {
    Write-Host "  Remaining providers:" -ForegroundColor Cyan
    foreach ($p in $remainingProviders) {
        $guid = $p.PSChildName
        $name = (Get-ItemProperty -Path $p.PSPath -ErrorAction SilentlyContinue).'(default)'
        Write-Host "    ✓ $name ($guid)" -ForegroundColor Green
    }
}

Write-Host "`n=== Cleanup Complete! ===" -ForegroundColor Green
Write-Host "`nCRITICAL NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. Close ALL PowerShell windows (including this one)" -ForegroundColor White
Write-Host "  2. RESTART WINDOWS (recommended)" -ForegroundColor White
Write-Host "  3. Or kill all PowerShell processes from Task Manager" -ForegroundColor White
Write-Host "`nWhy? Old DLLs are still loaded in memory and will cause crashes." -ForegroundColor Gray
Write-Host ""
