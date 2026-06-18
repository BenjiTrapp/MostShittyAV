# run_tests.ps1
# ==============================================================================
# Automated Test Suite for MostShittyAV Scanner
# Validates that detection and bypass scenarios produce expected results.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tests\scripts\run_tests.ps1
#
# Exit codes:
#   0 = All tests passed
#   1 = One or more tests failed
# ==============================================================================

param(
    [switch]$Verbose,
    [switch]$StopOnFailure
)

$ErrorActionPreference = "Continue"
$PROJECT_ROOT = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$SCANNER = Join-Path $PROJECT_ROOT "src\nim_antimalware_sim.exe"
$TEST_DIR = Join-Path $PROJECT_ROOT "tests"

# Build scanner if not present
if (-not (Test-Path $SCANNER)) {
    Write-Host "Scanner not found, building..." -ForegroundColor Yellow
    $source = Join-Path $PROJECT_ROOT "src\nim_antimalware_sim.nim"
    nim c --cpu:amd64 --out:$SCANNER $source
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FATAL: Could not build scanner!" -ForegroundColor Red
        exit 1
    }
}

# ==============================================================================
# Test Definition Format: @(RelativePath, ExpectedVerdict)
# Verdict: "MALICIOUS" or "BENIGN"
# ==============================================================================

$tests = @(
    # =========================================================================
    # 01_clean - All should be BENIGN
    # =========================================================================
    @("01_clean\clean.txt", "BENIGN"),
    @("01_clean\clean_umlaute.txt", "BENIGN"),
    @("01_clean\testfile.txt", "BENIGN"),

    # =========================================================================
    # 02_signature - Detection: Known signatures trigger MALICIOUS
    # =========================================================================
    @("02_signature\infected.txt", "MALICIOUS"),
    @("02_signature\trojan_sample.txt", "MALICIOUS"),
    @("02_signature\malware.ps1", "MALICIOUS"),

    # 02_signature - Bypass: Obfuscated signatures should pass as BENIGN
    @("02_signature\malware_bypass.ps1", "BENIGN"),
    # NOTE: The following old bypass files contain signature words in their
    # COMMENTS/descriptions which triggers detection. The obfuscation technique
    # itself works, but the file as a whole is detected due to explanatory text.
    @("02_signature\bypass_xor_encoding.ps1", "MALICIOUS"),    # "malware" in comment
    @("02_signature\bypass_charcode.ps1", "BENIGN"),
    @("02_signature\bypass_reversal.ps1", "BENIGN"),
    @("02_signature\bypass_env_vars.ps1", "BENIGN"),
    @("02_signature\bypass_rot13.ps1", "MALICIOUS"),           # "malware" in comment
    @("02_signature\bypass_hex_encoding.ps1", "MALICIOUS"),    # "malware" in comment
    @("02_signature\bypass_format_string.ps1", "MALICIOUS"),   # "malware" in comment
    @("02_signature\bypass_type_conversion.ps1", "BENIGN"),
    # New v3 bypasses (properly avoid signature words in all text)
    @("02_signature\bypass_utf16le.ps1", "BENIGN"),
    @("02_signature\bypass_null_insertion.ps1", "BENIGN"),
    @("02_signature\bypass_homoglyph.ps1", "BENIGN"),
    @("02_signature\bypass_zero_width.ps1", "BENIGN"),
    @("02_signature\bypass_download_cradle.ps1", "BENIGN"),

    # =========================================================================
    # 03_encoding - Detection: High non-printable ratio triggers MALICIOUS
    # =========================================================================
    @("03_encoding\packed.bin", "MALICIOUS"),
    @("03_encoding\mixed.bin", "MALICIOUS"),

    # 03_encoding - Bypass: Encoding evasion should pass as BENIGN
    @("03_encoding\utf16_bypass.txt", "BENIGN"),
    @("03_encoding\mixed_bypass.bin", "BENIGN"),
    @("03_encoding\bypass_sub64_nonprintable.bin", "BENIGN"),
    @("03_encoding\bypass_encrypted_payload.ps1", "BENIGN"),
    @("03_encoding\bypass_archive_container.zip", "BENIGN"),

    # =========================================================================
    # 04_extension - Extension heuristic (WARNING only, never blocks)
    # =========================================================================
    # Files with suspicious extensions but no other triggers = BENIGN
    @("04_extension\help.hta", "BENIGN"),
    @("04_extension\legacy.com", "BENIGN"),
    @("04_extension\component.wsf", "BENIGN"),
    @("04_extension\old.pif", "BENIGN"),
    @("04_extension\malware_no_ext", "BENIGN"),
    @("04_extension\suspicious_no_ext", "BENIGN"),

    # New structural bypasses
    @("04_extension\bypass_ads_hidden.ps1", "BENIGN"),
    @("04_extension\bypass_pe_stub.ps1", "BENIGN"),
    @("04_extension\bypass_polyglot.ps1", "BENIGN"),

    # =========================================================================
    # 05_small_executable - Detection: < 32 bytes + suspicious ext = MALICIOUS
    # =========================================================================
    @("05_small_executable\tiny.bat", "MALICIOUS"),

    # 05_small_executable - Bypass: Padding to >= 32 bytes
    @("05_small_executable\bypass_padded.bat", "BENIGN"),

    # =========================================================================
    # 06_amsi_bypass - AMSI-specific bypass techniques
    # =========================================================================
    # These contain signature words intentionally (testing detection)
    @("06_amsi_bypass\01_amsi_init_failed.ps1", "MALICIOUS"),

    # These should pass as BENIGN (no blocking signatures)
    @("06_amsi_bypass\02_amsi_memory_patch.ps1", "BENIGN"),
    @("06_amsi_bypass\03_powershell_downgrade.ps1", "MALICIOUS"),  # "malware trojan virus" in payload string
    @("06_amsi_bypass\11_dll_path_hijacking.ps1", "BENIGN"),
    @("06_amsi_bypass\12_wmi_subscription.ps1", "BENIGN"),
    @("06_amsi_bypass\13_etw_patching.ps1", "BENIGN")
)

# ==============================================================================
# Test Runner
# ==============================================================================

$totalTests = $tests.Count
$passed = 0
$failed = 0
$skipped = 0
$failures = @()

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  MostShittyAV - Automated Test Suite" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Scanner: $SCANNER"
Write-Host "  Tests:   $totalTests"
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($test in $tests) {
    $relativePath = $test[0]
    $expectedVerdict = $test[1]
    $fullPath = Join-Path $TEST_DIR $relativePath

    # Check file exists
    if (-not (Test-Path $fullPath)) {
        Write-Host "  [SKIP] $relativePath (file not found)" -ForegroundColor Yellow
        $skipped++
        continue
    }

    # Run scanner and capture output
    $output = & $SCANNER $fullPath 2>&1 | Out-String

    # Determine actual verdict from output
    $actualVerdict = "UNKNOWN"
    if ($output -match "Threat detected" -or $output -match "MALICIOUS") {
        $actualVerdict = "MALICIOUS"
    }
    elseif ($output -match "No threats found" -or $output -match "BENIGN") {
        $actualVerdict = "BENIGN"
    }

    # Compare
    if ($actualVerdict -eq $expectedVerdict) {
        $passed++
        if ($Verbose) {
            Write-Host "  [PASS] $relativePath = $actualVerdict" -ForegroundColor Green
        } else {
            Write-Host "  [PASS] $relativePath" -ForegroundColor Green
        }
    }
    else {
        $failed++
        Write-Host "  [FAIL] $relativePath" -ForegroundColor Red
        Write-Host "         Expected: $expectedVerdict | Got: $actualVerdict" -ForegroundColor Red
        $failures += @{
            Path = $relativePath
            Expected = $expectedVerdict
            Actual = $actualVerdict
        }

        if ($StopOnFailure) {
            Write-Host ""
            Write-Host "Stopping on first failure (-StopOnFailure)" -ForegroundColor Yellow
            break
        }
    }
}

# ==============================================================================
# Results Summary
# ==============================================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  TEST RESULTS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total:   $totalTests" -ForegroundColor White
Write-Host "  Passed:  $passed" -ForegroundColor Green
Write-Host "  Failed:  $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "  Skipped: $skipped" -ForegroundColor $(if ($skipped -gt 0) { "Yellow" } else { "White" })
Write-Host ""

if ($failed -gt 0) {
    Write-Host "  FAILED TESTS:" -ForegroundColor Red
    foreach ($f in $failures) {
        Write-Host "    - $($f.Path): expected $($f.Expected), got $($f.Actual)" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "  STATUS: FAILED" -ForegroundColor Red
    exit 1
}
elseif ($skipped -gt 0) {
    Write-Host "  STATUS: PASSED (with $skipped skipped)" -ForegroundColor Yellow
    exit 0
}
else {
    Write-Host "  STATUS: ALL TESTS PASSED" -ForegroundColor Green
    exit 0
}
