@echo off
REM ============================================================================
REM  MostShittyAV - EMERGENCY DEREGISTRATION SCRIPT
REM  Run as Administrator via CMD.exe
REM ============================================================================
REM
REM  USAGE:
REM    1. Open CMD.exe as Administrator (right-click > Run as Administrator)
REM    2. Navigate to this script's directory
REM    3. Run: emergency_unregister.cmd
REM
REM  WHAT THIS DOES:
REM    - Unregisters the AMSI provider DLL via regsvr32
REM    - Removes all registry keys manually as fallback
REM    - Verifies the cleanup was successful
REM
REM  SAFE TO RUN MULTIPLE TIMES - will not cause damage if already unregistered
REM ============================================================================

echo.
echo ============================================================
echo   MostShittyAV - EMERGENCY DEREGISTRATION
echo ============================================================
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script requires Administrator privileges!
    echo.
    echo Right-click CMD.exe and select "Run as Administrator"
    echo Then run this script again.
    echo.
    pause
    exit /b 1
)

echo [OK] Running with Administrator privileges
echo.

set PROVIDER_GUID={2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}
set DLL_PATH=%~dp0..\src\MostShittyAVWrapper.dll

REM ============================================================================
REM STEP 1: Unregister via regsvr32 (if DLL exists)
REM ============================================================================
echo [STEP 1] Attempting regsvr32 /u ...
if exist "%DLL_PATH%" (
    echo   DLL found: %DLL_PATH%
    regsvr32 /u /s "%DLL_PATH%"
    if %errorLevel% equ 0 (
        echo   [OK] regsvr32 /u completed successfully
    ) else (
        echo   [WARN] regsvr32 /u returned error (continuing with manual cleanup)
    )
) else (
    echo   [WARN] DLL not found at %DLL_PATH% - skipping regsvr32
    echo   Will perform manual registry cleanup instead
)
echo.

REM ============================================================================
REM STEP 2: Manual Registry Cleanup (Fallback)
REM ============================================================================
echo [STEP 2] Manual registry cleanup...
echo.

REM Remove AMSI Provider registration
echo   Removing AMSI Provider key...
reg delete "HKLM\SOFTWARE\Microsoft\AMSI\Providers\%PROVIDER_GUID%" /f >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] AMSI Provider key removed
) else (
    echo   [--] AMSI Provider key not found (already clean)
)

REM Remove InprocServer32 subkey first (required before parent can be deleted)
echo   Removing InprocServer32 key...
reg delete "HKLM\SOFTWARE\Classes\CLSID\%PROVIDER_GUID%\InprocServer32" /f >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] InprocServer32 key removed
) else (
    echo   [--] InprocServer32 key not found (already clean)
)

REM Remove CLSID registration
echo   Removing CLSID key...
reg delete "HKLM\SOFTWARE\Classes\CLSID\%PROVIDER_GUID%" /f >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] CLSID key removed
) else (
    echo   [--] CLSID key not found (already clean)
)

echo.

REM ============================================================================
REM STEP 3: Verification
REM ============================================================================
echo [STEP 3] Verifying cleanup...
echo.

set ALL_CLEAN=1

reg query "HKLM\SOFTWARE\Microsoft\AMSI\Providers\%PROVIDER_GUID%" >nul 2>&1
if %errorLevel% equ 0 (
    echo   [FAIL] AMSI Provider key still exists!
    set ALL_CLEAN=0
) else (
    echo   [OK] AMSI Provider key: CLEAN
)

reg query "HKLM\SOFTWARE\Classes\CLSID\%PROVIDER_GUID%" >nul 2>&1
if %errorLevel% equ 0 (
    echo   [FAIL] CLSID key still exists!
    set ALL_CLEAN=0
) else (
    echo   [OK] CLSID key: CLEAN
)

echo.
if %ALL_CLEAN% equ 1 (
    echo ============================================================
    echo   [SUCCESS] Provider fully deregistered!
    echo ============================================================
    echo.
    echo   The AMSI provider will no longer be loaded by new processes.
    echo   Already running processes may still have the old DLL loaded
    echo   until they are restarted.
    echo.
) else (
    echo ============================================================
    echo   [WARNING] Some keys could not be removed!
    echo ============================================================
    echo.
    echo   Try the following:
    echo     1. Close ALL PowerShell/CMD windows that may have loaded the DLL
    echo     2. Run this script again
    echo     3. If still failing, see RECOVERY INSTRUCTIONS below
    echo.
)

echo ============================================================
echo   RECOVERY INSTRUCTIONS (if system is unstable)
echo ============================================================
echo.
echo   If AMSI causes crashes or system instability:
echo.
echo   OPTION A - Safe Mode Registry Cleanup:
echo     1. Boot into Safe Mode (hold Shift + click Restart)
echo     2. Open CMD as Administrator
echo     3. Run this script again
echo.
echo   OPTION B - Manual regedit (if script fails):
echo     1. Run: regedit
echo     2. Navigate to:
echo        HKLM\SOFTWARE\Microsoft\AMSI\Providers\
echo     3. Delete the key: %PROVIDER_GUID%
echo     4. Navigate to:
echo        HKLM\SOFTWARE\Classes\CLSID\
echo     5. Delete the key: %PROVIDER_GUID%
echo     6. Restart the computer
echo.
echo   OPTION C - Command line (copy-paste these one by one):
echo     reg delete "HKLM\SOFTWARE\Microsoft\AMSI\Providers\%PROVIDER_GUID%" /f
echo     reg delete "HKLM\SOFTWARE\Classes\CLSID\%PROVIDER_GUID%\InprocServer32" /f
echo     reg delete "HKLM\SOFTWARE\Classes\CLSID\%PROVIDER_GUID%" /f
echo.
echo   OPTION D - System Restore:
echo     1. Boot into Safe Mode
echo     2. Run: rstrui.exe
echo     3. Choose a restore point from before registration
echo.
echo ============================================================
echo.
pause
