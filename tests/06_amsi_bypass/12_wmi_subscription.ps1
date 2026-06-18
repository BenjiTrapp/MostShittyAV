# Bypass: WMI/CIM Event Subscription (Living off the Land)
# ==========================================================
# WMI event subscriptions execute code in a separate process (wmiprvse.exe).
# AMSI hooks are per-process -- the subscription runs in a different context
# than the originating PowerShell session.
#
# This technique:
#   1. Creates a WMI event subscription that triggers on a condition
#   2. The action (CommandLineEventConsumer) runs in wmiprvse.exe
#   3. wmiprvse.exe may or may not load AMSI providers
#   4. Content is fragmented across WMI objects (no contiguous signatures)
#
# This is a "Living off the Land" (LOLBin) technique -- uses only
# built-in Windows components, no external binaries needed.
#
# EXPECTED RESULT: BENIGN (no signatures, patterns are warning-only)

Write-Host "=== WMI Event Subscription ==="
Write-Host ""

# The command is split across WMI objects -- never exists as contiguous string
$part1 = "pow" + "ersh" + "ell"
$part2 = "-e" + "nc "  # -EncodedCommand
$part3 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("Write-Host 'test'"))

$fullCommand = "$part1 $part2 $part3"

Write-Host "Command reconstructed at runtime: $fullCommand"
Write-Host ""
Write-Host "In a real attack, this would:"
Write-Host "  1. Register __EventFilter with WQL query"
Write-Host "  2. Register CommandLineEventConsumer with encoded content"
Write-Host "  3. Bind them with __FilterToConsumerBinding"
Write-Host "  4. Content executes in wmiprvse.exe context"
Write-Host ""
Write-Host "Scanner limitations:"
Write-Host "  - Cannot inspect WMI repository"
Write-Host "  - Cannot correlate fragmented WMI objects"
Write-Host "  - Pattern check is warning-only (does not block)"
Write-Host "  - Cross-process execution escapes per-process AMSI hooks"

# Demonstrate the WMI classes involved (read-only, no actual persistence)
Write-Host ""
Write-Host "Existing WMI subscriptions on this system:"
Get-WmiObject -Namespace root\subscription -Class __EventFilter 2>$null |
    Select-Object Name, Query | Format-Table -AutoSize
