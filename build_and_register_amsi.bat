@echo off
REM build_and_register_amsi.bat
REM Build and register the Nim AMSI Demo provider
REM RUN AS ADMINISTRATOR

echo.
echo ============================================================
echo   Nim AMSI Demo Provider - Build and Register
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

REM Configuration
set DLL_NAME=NimAmsiDemo.dll
set SOURCE_FILE=amsi_demo_provider.nim
set PROVIDER_GUID={A1B2C3D4-E5F6-7890-ABCD-EF1234567890}

echo Step 1: Building DLL...
echo.

REM Remove old DLL if it exists
if exist %DLL_NAME% (
    echo Removing old %DLL_NAME%...
    del /f %DLL_NAME% 2>nul
    if exist %DLL_NAME% (
        echo   WARNING: Could not delete old DLL (may be in use)
        echo   Trying to rename it...
        move /y %DLL_NAME% %DLL_NAME%.old >nul 2>&1
    )
)

REM Build with Nim
echo Compiling %SOURCE_FILE%...
echo Command: nim c --app:lib --cpu:amd64 --mm:orc -d:release --out:%DLL_NAME% %SOURCE_FILE%
echo.

nim c --app:lib --cpu:amd64 --mm:orc -d:release --out:%DLL_NAME% %SOURCE_FILE%

if %errorLevel% neq 0 (
    echo.
    echo ERROR: Build failed!
    echo Check the compilation errors above.
    pause
    exit /b 1
)

REM Check if DLL was created
if not exist %DLL_NAME% (
    echo.
    echo ERROR: DLL was not created!
    pause
    exit /b 1
)

echo.
echo Build successful!
for %%A in (%DLL_NAME%) do echo   Size: %%~zA bytes
echo.

echo Step 2: Registering AMSI Provider...
echo.

REM Get absolute path
set DLL_PATH=%CD%\%DLL_NAME%
echo DLL path: %DLL_PATH%
echo.

REM Register with regsvr32
echo Running: regsvr32 /s "%DLL_PATH%"
regsvr32 /s "%DLL_PATH%"

if %errorLevel% neq 0 (
    echo ERROR: Registration failed with exit code %errorLevel%
    echo.
    echo Common errors:
    echo   Exit code 3: DllRegisterServer not found
    echo   Exit code 4: DllRegisterServer failed
    echo   Exit code 5: Access denied
    pause
    exit /b 1
)

echo Registration command completed.
echo.

echo Step 3: Verifying registration...
echo.

REM Check AMSI provider registry key
reg query "HKLM\SOFTWARE\Microsoft\AMSI\Providers\%PROVIDER_GUID%" >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] AMSI Provider registered
) else (
    echo   [FAIL] AMSI Provider not found in registry
)

REM Check CLSID registry key
reg query "HKLM\SOFTWARE\Classes\CLSID\%PROVIDER_GUID%" >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] COM CLSID registered
) else (
    echo   [FAIL] COM CLSID not found in registry
)

REM Check InprocServer32
reg query "HKLM\SOFTWARE\Classes\CLSID\%PROVIDER_GUID%\InprocServer32" >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] InprocServer32 configured
) else (
    echo   [FAIL] InprocServer32 not found
)

echo.
echo ============================================================
echo   Build and Registration Complete!
echo ============================================================
echo.
echo IMPORTANT NEXT STEPS:
echo   1. Close ALL PowerShell windows
echo   2. Open a NEW PowerShell window
echo   3. Test with: Write-Host "Testing AMSI"
echo.
echo Your provider will log detailed information about each scan!
echo.
echo To view registry details:
echo   reg query "HKLM\SOFTWARE\Microsoft\AMSI\Providers\%PROVIDER_GUID%"
echo.
echo To unregister:
echo   regsvr32 /u "%DLL_PATH%"
echo.
pause
