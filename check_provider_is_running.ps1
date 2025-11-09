# check_provider_is_running.ps1

# AMSI Provider GUID
$providerGuid = "{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}"

# Registry paths
$amsiProviderPath = "HKLM:\SOFTWARE\Microsoft\AMSI\Providers\$providerGuid"
$clsidPath = "HKLM:\SOFTWARE\Classes\CLSID\$providerGuid"

# Check AMSI Provider registration
Write-Host "Checking AMSI Provider registration..."
if (Test-Path $amsiProviderPath) {
    Write-Host "AMSI Provider is registered."
    Get-ItemProperty $amsiProviderPath | Format-List
} else {
    Write-Host "AMSI Provider is NOT registered."
}

# Check COM CLSID registration
Write-Host "`nChecking COM CLSID registration..."
if (Test-Path $clsidPath) {
    Write-Host "COM CLSID is registered."
    Get-ItemProperty $clsidPath | Format-List
} else {
    Write-Host "COM CLSID is NOT registered."
}