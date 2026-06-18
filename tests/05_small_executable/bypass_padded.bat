# Bypass: Small Executable Padding
# ==================================
# The scanner blocks files that are:
#   - Less than 32 bytes AND
#   - Have a suspicious extension (.bat, .exe, .ps1, etc.)
#
# Simply padding the file to >= 32 bytes defeats this check entirely.
# Comments, whitespace, or NOP-equivalent statements add bytes without
# changing the functional behavior.
#
# Compare with tests/05_small_executable/tiny.bat (19 bytes = MALICIOUS)
# This file is the same payload but padded to avoid detection.
#
# EXPECTED RESULT: BENIGN (file >= 32 bytes, no signature match)

@echo off
REM Padding to exceed 32 byte threshold
echo payload_executed
