# Bypass: Null Byte Insertion
# ============================
# The scanner searches for contiguous signature strings in file bytes.
# By inserting null bytes (0x00) between characters, the signature is broken
# at the byte level but can be reconstructed by filtering out nulls.
#
# Target with nulls: char + NUL + char + NUL + ...
# Scanner sees interleaved nulls -- no contiguous match possible.
#
# EXPECTED RESULT: BENIGN (null bytes break contiguous signature match)

# Null-separated byte array (target word with NUL between each char)
$nullSeparated = @(109, 0, 97, 0, 108, 0, 119, 0, 97, 0, 114, 0, 101, 0)

# Runtime reconstruction: filter out null bytes
$cleanBytes = $nullSeparated | Where-Object { $_ -ne 0 }
$result = -join ($cleanBytes | ForEach-Object { [char]$_ })

Write-Host "Reconstructed from null-separated bytes: $result"
Write-Host "The raw file never contains the contiguous signature string"
