# Bypass: UTF-16LE Signature Evasion
# ====================================
# The scanner's toLowerAsciiByte converts bytes and does substring matching.
# UTF-16LE encodes each ASCII character as 2 bytes (char + 0x00).
# The target word in UTF-16LE = 6D 00 61 00 6C 00 77 00 61 00 72 00 65 00
# The null bytes between characters break the contiguous substring match.
# Scanner sees: m NUL a NUL l NUL w NUL a NUL r NUL e NUL -- no match.
#
# EXPECTED RESULT: BENIGN (signature not matched due to null byte interleaving)

# Store the target keyword as UTF-16LE bytes (no plaintext signature in file!)
$payload = [System.Text.Encoding]::Unicode.GetBytes(
    [char]109 + [char]97 + [char]108 + [char]119 + [char]97 + [char]114 + [char]101
)

# At runtime, decode back to string
$decoded = [System.Text.Encoding]::Unicode.GetString($payload)

# Execute the decoded keyword
Write-Host "Recovered keyword: $decoded"
Write-Host "This file never contains the target word as contiguous ASCII bytes"
