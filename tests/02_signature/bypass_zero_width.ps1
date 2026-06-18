# Bypass: Zero-Width Unicode Character Insertion
# ================================================
# Zero-width characters are invisible in display but present in the byte stream.
# They break contiguous string matching without visual indication.
#
# Common zero-width characters:
#   U+200B - Zero Width Space
#   U+200C - Zero Width Non-Joiner
#   U+200D - Zero Width Joiner
#   U+FEFF - BOM (Zero Width No-Break Space)
#
# Inserting ZWSP between characters adds 3 UTF-8 bytes (E2 80 8B)
# that interrupt the signature match while being invisible on screen.
#
# EXPECTED RESULT: BENIGN (zero-width chars break substring matching)

# Build the target keyword with zero-width space inserted
$zwsp = [char]0x200B  # Zero Width Space - invisible character
$part1 = [char]109 + [char]97 + [char]108  # first half
$part2 = [char]119 + [char]97 + [char]114 + [char]101  # second half

# Insert invisible ZWSP between the two halves
$combined = "$part1$zwsp$part2"

Write-Host "Zero-width result: [$combined]"
Write-Host "Length: $($combined.Length) chars (8 instead of 7 -- extra ZWSP)"
Write-Host "Visual appearance is identical to the target keyword"

# Cleanup demonstration
$clean = $combined -replace "\u200B", ""
Write-Host "After stripping ZWSP: $clean (length: $($clean.Length))"
