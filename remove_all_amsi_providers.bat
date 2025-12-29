@echo off
REM remove_all_amsi_providers.bat
REM Remove all AMSI providers using CMD (PowerShell-independent)
REM RUN AS ADMINISTRATOR

echo.
echo ============================================================
echo   AMSI Provider Complete Removal (CMD)
echo ============================================================
echo.

REM Check if running as admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Must run as Administrator!
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo Step 1: Unregistering all AMSI provider DLLs...
echo.

REM Unregister known DLLs
echo Unregistering NimAmsiDemo.dll...
regsvr32 /u /s "X:\MostShittyAV\NimAmsiDemo.dll" 2>nul
if %errorLevel% equ 0 (
    echo   OK: NimAmsiDemo.dll unregistered
) else (
    echo   SKIP: NimAmsiDemo.dll not found or already unregistered
)

echo Unregistering MostShittyAVWrapper.dll...
regsvr32 /u /s "X:\MostShittyAV\MostShittyAVWrapper.dll" 2>nul
if %errorLevel% equ 0 (
    echo   OK: MostShittyAVWrapper.dll unregistered
) else (
    echo   SKIP: MostShittyAVWrapper.dll not found or already unregistered
)

echo.
echo Step 2: Deleting AMSI provider registry keys...
echo.

REM Remove Nim provider
echo Removing Nim AMSI provider...
reg delete "HKLM\SOFTWARE\Microsoft\AMSI\Providers\{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}" /f >nul 2>&1
if %errorLevel% equ 0 (
    echo   OK: Nim AMSI provider removed
) else (
    echo   SKIP: Nim AMSI provider not found
)

reg delete "HKLM\SOFTWARE\Classes\CLSID\{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}" /f >nul 2>&1
if %errorLevel% equ 0 (
    echo   OK: Nim CLSID removed
) else (
    echo   SKIP: Nim CLSID not found
)

REM Remove old MostShittyAV provider
echo Removing old MostShittyAV provider...
reg delete "HKLM\SOFTWARE\Microsoft\AMSI\Providers\{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}" /f >nul 2>&1
if %errorLevel% equ 0 (
    echo   OK: Old AMSI provider removed
) else (
    echo   SKIP: Old AMSI provider not found
)

reg delete "HKLM\SOFTWARE\Classes\CLSID\{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}" /f >nul 2>&1
if %errorLevel% equ 0 (
    echo   OK: Old CLSID removed
) else (
    echo   SKIP: Old CLSID not found
)

REM Remove broken Windows Defender provider
echo Removing broken Windows Defender AMSI provider...
reg delete "HKLM\SOFTWARE\Microsoft\AMSI\Providers\{2781761E-28E0-4109-99FE-B9D127C57AFE}" /f >nul 2>&1
if %errorLevel% equ 0 (
    echo   OK: Defender AMSI provider removed
) else (
    echo   SKIP: Defender AMSI provider not found
)

echo.
echo Step 3: Verification...
echo.

echo Remaining AMSI providers:
reg query "HKLM\SOFTWARE\Microsoft\AMSI\Providers" 2>nul
if %errorLevel% neq 0 (
    echo   NONE - All AMSI providers removed!
)

echo.
echo ============================================================
echo   Cleanup Complete!
echo ============================================================
echo.
echo CRITICAL NEXT STEPS:
echo   1. Close ALL applications (especially PowerShell)
echo   2. RESTART WINDOWS (highly recommended)
echo   3. After restart, PowerShell should work normally
echo.
echo Why restart? Old DLLs are still loaded in memory.
echo A restart ensures everything is clean.
echo.
pause
