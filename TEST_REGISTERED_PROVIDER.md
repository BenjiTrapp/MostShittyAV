# Testing the Registered AMSI Provider

This guide shows how to register and verify that your AMSI provider is actually being loaded by Windows processes.

## Prerequisites

- Administrator privileges
- [Process Monitor](https://learn.microsoft.com/en-us/sysinternals/downloads/procmon) from Sysinternals
- MostShittyAVWrapper.dll built and ready

## Step 1: Build the DLL

```powershell
.\quick_build.ps1
```

Expected output:
```
Build successful!
DLL: MostShittyAVWrapper.dll
Size: 425.12 KB
```

## Step 2: Register the AMSI Provider

**Important: Run PowerShell as Administrator**

```powershell
.\build_and_register.ps1 -BuildAndRegister
```

Or manually:
```powershell
regsvr32 "X:\MostShittyAV\MostShittyAVWrapper.dll"
```

## Step 3: Verify Registration

```powershell
.\build_and_register.ps1 -Status
```

Or use the check script:
```powershell
.\check_provider_is_running.ps1
```

You should see:
```
AMSI Registration: REGISTERED ✓
COM CLSID: REGISTERED ✓
```

Verify registry keys manually:
```powershell
# Check AMSI Provider
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\AMSI\Providers\{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}"

# Check COM CLSID
Get-ItemProperty "HKLM:\SOFTWARE\Classes\CLSID\{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}\InprocServer32"
```

## Step 4: Setup Process Monitor

### 4.1 Download and Launch Process Monitor

1. Download from: https://learn.microsoft.com/en-us/sysinternals/downloads/procmon
2. Extract and run `Procmon.exe` **as Administrator**
3. Accept the license agreement

### 4.2 Configure Filters

Process Monitor shows ALL system activity by default. We need to filter for our DLL.

**Click Filter → Filter... (or press Ctrl+L)**

Add the following filters:

**Filter 1: DLL Path**
```
Path contains MostShittyAVWrapper.dll
Include
Add
```

**Filter 2: DLL Name**
```
Path contains MostShittyAVWrapper
Include
Add
```

**Filter 3: Our CLSID (optional)**
```
Path contains 2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A
Include
Add
```

Click **OK** to apply filters.

### 4.3 Configure Columns (Optional)

To see more useful information:

1. Right-click on column headers
2. Select **Select Columns...**
3. Enable these columns:
   - Process Name
   - PID
   - Operation
   - Path
   - Result
   - Detail

### 4.4 Clear Existing Events

Click **Edit → Clear Display** (or press Ctrl+X)

## Step 5: Test Provider Loading

### Test 1: Launch PowerShell

With Process Monitor running and filtered:

```powershell
# Start a new PowerShell process
Start-Process powershell
```

**What to look for in Process Monitor:**

You should see events like:
```
powershell.exe  CreateFile  X:\MostShittyAV\MostShittyAVWrapper.dll  SUCCESS
powershell.exe  Load Image  MostShittyAVWrapper.dll  SUCCESS
powershell.exe  QueryNameInformationFile  MostShittyAVWrapper.dll  SUCCESS
```

**If you see these events:** ✅ Your AMSI provider is being loaded!

**If you see nothing:** ❌ Provider is not loading (see Troubleshooting section)

### Test 2: Launch Multiple Processes

Try other AMSI-aware applications:

```powershell
# PowerShell
Start-Process powershell

# Windows Script Host
Start-Process wscript

# Command Prompt (if AMSI is enabled)
Start-Process cmd
```

Watch Process Monitor for `MostShittyAVWrapper.dll` load events.

### Test 3: Registry Access

Look for registry access to your provider's keys:

**Filter for:**
```
Path contains AMSI\Providers
Include
```

You should see:
```
powershell.exe  RegOpenKey  HKLM\SOFTWARE\Microsoft\AMSI\Providers\{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}  SUCCESS
powershell.exe  RegQueryValue  ...  SUCCESS
```

## Step 6: Verify DLL Functions Are Called

To see if your DLL's functions are actually being invoked, you can:

### Option A: Add Debug Output to Your Code

In `nim_amsi_wrapper_dll.nim`, the functions already have echo statements:

```nim
proc DllGetClassObject(...): HRESULT {.exportc, stdcall, dynlib.} =
  ...
  echo "DllGetClassObject (wrapper) aufgerufen"  # This will output when called
  ...
```

### Option B: Use DebugView

1. Download [DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview)
2. Run as Administrator
3. Enable: Capture → Capture Global Win32
4. Launch a new PowerShell window
5. Look for debug output from your DLL

### Option C: Attach a Debugger

For advanced debugging:

```powershell
# Build with debug symbols
nim c --app:lib --cpu:amd64 --debugger:native --out:MostShittyAVWrapper.dll nim_amsi_wrapper_dll.nim

# Use Visual Studio or WinDbg to attach to powershell.exe
```

## Expected Process Monitor Output

When everything works correctly, you should see:

```
Time        Process         Operation       Path                                    Result
----------  --------------  --------------  --------------------------------------  -------
12:34:56    powershell.exe  CreateFile      X:\...\MostShittyAVWrapper.dll         SUCCESS
12:34:56    powershell.exe  QueryAttributes X:\...\MostShittyAVWrapper.dll         SUCCESS
12:34:56    powershell.exe  CreateFileMap   X:\...\MostShittyAVWrapper.dll         SUCCESS
12:34:56    powershell.exe  Load Image      MostShittyAVWrapper.dll                SUCCESS
12:34:56    powershell.exe  QueryBasicInfo  X:\...\MostShittyAVWrapper.dll         SUCCESS
```

## Troubleshooting

### Provider Not Loading

**Problem:** No events in Process Monitor

**Solutions:**

1. **Verify Registration:**
   ```powershell
   .\build_and_register.ps1 -Status
   ```

2. **Check DLL Path in Registry:**
   ```powershell
   $path = (Get-ItemProperty "HKLM:\SOFTWARE\Classes\CLSID\{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}\InprocServer32").'(default)'
   Write-Host "DLL Path: $path"
   Test-Path $path  # Should return True
   ```

3. **Verify DLL is Accessible:**
   ```powershell
   $path = "X:\MostShittyAV\MostShittyAVWrapper.dll"
   icacls $path
   # Should show Read & Execute permissions for Everyone or Users
   ```

4. **Check for COM/AMSI Errors in Event Viewer:**
   ```powershell
   # Open Event Viewer
   eventvwr.msc
   
   # Navigate to: Windows Logs → Application
   # Filter for Source: AMSI, COM+, etc.
   ```

### DLL Loads But Functions Not Called

**Problem:** DLL loads in Process Monitor but no function calls

**Possible Causes:**

1. **DllGetClassObject failing** - Check return codes
2. **COM registration incomplete** - Verify all registry keys
3. **Wrong threading model** - Should be "Both"
4. **AMSI choosing different provider** - Windows may prioritize other providers

**Debug Steps:**

```powershell
# Check Windows Defender AMSI logs
Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 20

# Check COM initialization
Get-WinEvent -LogName "System" -MaxEvents 50 | Where-Object {$_.Message -like "*COM*"}
```

### Access Denied

**Problem:** Registration fails with "Access Denied"

**Solution:**
- Run PowerShell as Administrator
- Check User Account Control (UAC) settings
- Verify you have write access to HKLM

### DLL In Use

**Problem:** Cannot rebuild DLL (file locked)

**Solution:**
```powershell
# Find processes using the DLL
Get-Process | Where-Object { 
    try { 
        $_.Modules.FileName -like "*MostShittyAVWrapper*" 
    } catch { 
        $false 
    }
} | Select-Object ProcessName, Id

# Close those processes or restart computer
```

## Verification Checklist

Before testing, verify:

- [ ] DLL exists: `X:\MostShittyAV\MostShittyAVWrapper.dll`
- [ ] AMSI Provider key exists in registry
- [ ] COM CLSID key exists in registry
- [ ] InprocServer32 path points to correct DLL location
- [ ] ThreadingModel is set to "Both"
- [ ] DLL is not locked/in-use
- [ ] Process Monitor is running as Administrator
- [ ] Filters are configured correctly
- [ ] Testing with a NEW PowerShell window (not existing one)

## Advanced Testing

### Test with AMSI Scanner

Create a test PowerShell script that AMSI should scan:

```powershell
# test_amsi_scan.ps1
$code = @"
Write-Host "This is a test"
# AMSI scans this content
"@

Invoke-Expression $code
```

Run it in a new PowerShell window:
```powershell
.\test_amsi_scan.ps1
```

Watch Process Monitor for your DLL being loaded and accessed.

### Test with Malicious String

```powershell
# In a new PowerShell window
$test = "AMSI Test " + "X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*"
Write-Host $test
```

AMSI should scan this content and your provider may be invoked.

## Uninstalling the Provider

To remove the provider after testing:

```powershell
# As Administrator
.\build_and_register.ps1 -Unregister

# Verify
.\build_and_register.ps1 -Status
```

Or manually:
```powershell
regsvr32 /u "X:\MostShittyAV\MostShittyAVWrapper.dll"
```

## Summary

A successfully registered and loaded AMSI provider will show:

1. ✅ Registry keys present in HKLM
2. ✅ DLL load events in Process Monitor when starting AMSI-aware apps
3. ✅ DLL functions being called (visible via debug output)
4. ✅ No errors in Event Viewer related to COM or AMSI

If all checks pass, your AMSI provider is working correctly! 🎉

## References

- [Process Monitor](https://learn.microsoft.com/en-us/sysinternals/downloads/procmon)
- [DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview)
- [AMSI Documentation](https://docs.microsoft.com/en-us/windows/win32/amsi/)
- [COM Registration](https://docs.microsoft.com/en-us/windows/win32/com/registering-com-applications)
