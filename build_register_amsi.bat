@echo off
REM build_and_register.bat
REM Compile and register the Nim AMSI demo provider
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

REM Set variables
set DLL_NAME=NimAmsiDemo.dll
set SOURCE_FILE=amsi_demo_provider.nim
set PROVIDER_GUID={A1B2C3D4-E5F6-7890-ABCD-EF1234567890}

echo Step 1: Building DLL...
echo.

REM Remove old DLL if exists
if exist %DLL_NAME% (
    echo Removing old DLL...
    del /F /Q %DLL_NAME% 2>nul
)

REM Compile with Nim
echo Compiling %SOURCE_FILE%...
nim c --app:lib --cpu:amd64 --mm:orc -d:release --out:%DLL_NAME% %SOURCE_FILE%

if %errorLevel% neq 0 (
    echo.
    echo ERROR: Build failed!
    echo Check the compilation errors above.
    pause
    exit /b 1
)

if not exist %DLL_NAME% (
    echo.
    echo ERROR: DLL not created!
    pause
    exit /b 1
)

echo.
echo SUCCESS: DLL built successfully!
for %%I in (%DLL_NAME%) do echo   Size: %%~zI bytes
echo.

echo Step 2: Registering AMSI provider...
echo.

REM Get full path to DLL
set FULL_DLL_PATH=%CD%\%DLL_NAME%
echo DLL Path: %FULL_DLL_PATH%
echo.

REM Register with regsvr32
echo Running: regsvr32 /s "%FULL_DLL_PATH%"
regsvr32 /s "%FULL_DLL_PATH%"

if %errorLevel% neq 0 (
    echo.
    echo ERROR: Registration failed!
    echo Exit code: %errorLevel%
    pause
    exit /b 1
)

echo   OK: regsvr32 completed
echo.

REM Wait a moment for registry to update
timeout /t 2 /nobreak >nul

echo Step 3: Verification...
echo.

REM Check AMSI provider registration
echo Checking AMSI provider registration...
reg query "HKLM\SOFTWARE\Microsoft\AMSI\Providers\%PROVIDER_GUID%" >nul 2>&1
if %errorLevel% equ 0 (
    echo   OK: AMSI provider registered
) else (
    echo   WARNING: AMSI provider key not found
)

REM Check CLSID registration
echo Checking COM CLSID registration...
reg query "HKLM\SOFTWARE\Classes\CLSID\%PROVIDER_GUID%" >nul 2>&1
if %errorLevel% equ 0 (
    echo   OK: COM CLSID registered
) else (
    echo   WARNING: CLSID key not found
)

echo.
echo ============================================================
echo   Registration Complete!
echo ============================================================
echo.
echo IMPORTANT:
echo   1. Close ALL PowerShell windows
echo   2. Open a NEW PowerShell window to test
echo   3. The provider will log all AMSI scan requests
echo.
echo To test, run in new PowerShell:
echo   Write-Host "Testing AMSI provider"
echo.
pause
