# Bypass: Provider DLL Hijacking via PATH Manipulation
# ======================================================
# AMSI providers are loaded as COM InprocServer32 DLLs.
# If an attacker can place a stub DLL earlier in the DLL search path,
# Windows will load the attacker's DLL instead of the real provider.
#
# DLL Search Order:
#   1. Application directory
#   2. System directory (System32)
#   3. 16-bit system directory
#   4. Windows directory
#   5. Current directory
#   6. PATH environment variable directories
#
# Attack: Place a no-op DLL that returns AMSI_RESULT_CLEAN for everything.
# Does NOT require admin rights if targeting per-user PATH.
#
# EXPECTED RESULT: BENIGN (scanner cannot detect DLL path manipulation)

Write-Host "=== DLL Hijacking via PATH Manipulation ==="
Write-Host ""

# Show the current PATH directories
$paths = $env:PATH -split ";"
Write-Host "DLL Search PATH directories (in order):"
$i = 1
foreach ($p in $paths) {
    if ($p -ne "") {
        Write-Host "  $i. $p"
        $i++
    }
}

Write-Host ""
Write-Host "Attack scenario:"
Write-Host "  1. Create a stub DLL implementing the AMSI provider interface"
Write-Host "  2. Stub always returns AMSI_RESULT_CLEAN (0)"
Write-Host "  3. Place stub in a user-writable PATH directory"
Write-Host "  4. If loaded before the real provider, all scans pass"
Write-Host ""

# Check for writable directories in PATH
Write-Host "Checking for user-writable directories in PATH..."
foreach ($p in $paths) {
    if ($p -ne "" -and (Test-Path $p)) {
        try {
            $testFile = Join-Path $p "___write_test_$PID.tmp"
            [IO.File]::WriteAllText($testFile, "test")
            Remove-Item $testFile -Force
            Write-Host "  [WRITABLE] $p" -ForegroundColor Yellow
        } catch {
            # Not writable - skip
        }
    }
}
Write-Host ""
Write-Host "Any writable PATH directory is a potential DLL hijacking target."
