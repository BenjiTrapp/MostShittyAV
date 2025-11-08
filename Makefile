.PHONY: build test_extension_bypass test_signature_detection

build:
	nim c --app:lib --cpu:amd64 --os:windows amsi_raccoon_lab.nim

test_extension_bypass:
	nim c -r nim_antimalware_sim.nim test\document.pdf.exe test\help.hta test\05\legacy.com test\05\malware test\05\suspicious_file

test_signature_detection:
	nim c -r nim_antimalware_sim.nim test\02_malware.ps1 test\02_malware_bypass.ps1