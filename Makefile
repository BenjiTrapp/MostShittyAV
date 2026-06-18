.PHONY: build dll clean test_all test_extension_bypass test_signature_detection test_encoding test_clean test_amsi_bypass register unregister emergency_unregister status

# Build the AMSI Provider DLL
dll:
	@powershell -ExecutionPolicy Bypass -File scripts/quick_build.ps1

# Build the standalone scanner EXE
exe:
	nim c --cpu:amd64 --out:src/nim_antimalware_sim.exe src/nim_antimalware_sim.nim

# Alias for dll
build: dll

# Build everything (DLL + EXE)
all: dll exe

# Build and register (requires Admin)
install: dll
	@echo "Note: Registration requires Administrator privileges"
	@powershell -ExecutionPolicy Bypass -File scripts/build_and_register.ps1 -BuildAndRegister

# Unregister the provider (requires Admin)
unregister:
	@powershell -ExecutionPolicy Bypass -File scripts/build_and_register.ps1 -Unregister

# Emergency deregistration via CMD (requires Admin)
emergency_unregister:
	@scripts\emergency_unregister.cmd

# Check registration status
status:
	@powershell -ExecutionPolicy Bypass -File scripts/build_and_register.ps1 -Status

# Clean build artifacts
clean:
	@if exist src\MostShittyAVWrapper.dll del /F /Q src\MostShittyAVWrapper.dll
	@if exist src\MostShittyAVWrapper.dll.old del /F /Q src\MostShittyAVWrapper.dll.old
	@if exist src\nim_antimalware_sim.exe del /F /Q src\nim_antimalware_sim.exe
	@echo Cleaned build artifacts

# Generate test files
generate_tests:
	@powershell -ExecutionPolicy Bypass -File tests/scripts/create_test_files.ps1
	@powershell -ExecutionPolicy Bypass -File tests/scripts/create_bypass_files.ps1

# Run all tests
test_all: test_clean test_signature_detection test_encoding test_extension_bypass test_small_executable test_amsi_bypass
	@echo All tests completed.

# Test category: Clean files (should all be BENIGN)
test_clean:
	nim c -r src/nim_antimalware_sim.nim tests/01_clean/clean.txt tests/01_clean/clean_umlaute.txt

# Test category: Signature detection + bypass
test_signature_detection:
	nim c -r src/nim_antimalware_sim.nim tests/02_signature/malware.ps1 tests/02_signature/trojan_sample.txt tests/02_signature/malware_bypass.ps1

# Test category: Encoding/binary detection + bypass
test_encoding:
	nim c -r src/nim_antimalware_sim.nim tests/03_encoding/utf16.txt tests/03_encoding/packed.bin tests/03_encoding/utf16_bypass.txt tests/03_encoding/mixed_bypass.bin

# Test category: Extension heuristic + bypass
test_extension_bypass:
	nim c -r src/nim_antimalware_sim.nim tests/04_extension/extension_detected.exe tests/04_extension/help.hta tests/04_extension/legacy.com tests/04_extension/malware_no_ext tests/04_extension/suspicious_no_ext

# Test category: Small executable check
test_small_executable:
	nim c -r src/nim_antimalware_sim.nim tests/05_small_executable/tiny.bat

# Test category: AMSI bypass techniques
test_amsi_bypass:
	nim c -r src/nim_antimalware_sim.nim tests/06_amsi_bypass/01_amsi_init_failed.ps1 tests/06_amsi_bypass/02_amsi_memory_patch.ps1 tests/06_amsi_bypass/03_powershell_downgrade.ps1 tests/06_amsi_bypass/04_base64_encoded_command.ps1 tests/06_amsi_bypass/05_com_hijacking.ps1
