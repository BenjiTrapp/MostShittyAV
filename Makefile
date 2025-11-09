.PHONY: build dll clean test_extension_bypass test_signature_detection register unregister status

# Build the AMSI Provider DLL
dll:
	@powershell -ExecutionPolicy Bypass -File quick_build.ps1

# Alias for dll
build: dll

# Build and register (requires Admin)
install: dll
	@echo "Note: Registration requires Administrator privileges"
	@powershell -ExecutionPolicy Bypass -File build_and_register.ps1 -BuildAndRegister

# Unregister the provider (requires Admin)
unregister:
	@powershell -ExecutionPolicy Bypass -File build_and_register.ps1 -Unregister

# Check registration status
status:
	@powershell -ExecutionPolicy Bypass -File build_and_register.ps1 -Status

# Clean build artifacts
clean:
	@if exist MostShittyAVWrapper.dll del /F /Q MostShittyAVWrapper.dll
	@if exist MostShittyAVWrapper.dll.old del /F /Q MostShittyAVWrapper.dll.old
	@if exist test_register.exe del /F /Q test_register.exe
	@echo Cleaned build artifacts

# Legacy test targets
test_extension_bypass:
	nim c -r nim_antimalware_sim.nim test\document.pdf.exe test\help.hta test\05\legacy.com test\05\malware test\05\suspicious_file

test_signature_detection:
	nim c -r nim_antimalware_sim.nim test\02_malware.ps1 test\02_malware_bypass.ps1