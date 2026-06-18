# Bypass: Unicode Homoglyph Substitution
# ========================================
# The scanner's toLowerAsciiByte() only handles ASCII range (0x41-0x5A).
# It does not perform Unicode normalization.
# By replacing ASCII characters with visually identical Unicode characters,
# the signature match fails completely.
#
# Example: ASCII 'a' (U+0061) vs Cyrillic 'a' (U+0430) - looks identical!
# Scanner sees UTF-8 bytes D0 B0 instead of 61 -- no match.
#
# EXPECTED RESULT: BENIGN (Unicode homoglyphs break ASCII signature matching)

# Using Cyrillic characters that look identical to Latin:
# Cyrillic 'a' (U+0430) instead of Latin 'a' (U+0061)
# Cyrillic 'e' (U+0435) instead of Latin 'e' (U+0065)

# Build keyword with homoglyphs (m + cyrillic_a + l + w + cyrillic_a + r + cyrillic_e)
$keyword = "m" + [char]0x0430 + "lw" + [char]0x0430 + "r" + [char]0x0435

Write-Host "Homoglyph result: $keyword"
Write-Host "Visually identical to the target but bytes differ at positions 2, 5, 7"
Write-Host "Scanner cannot match because toLowerAsciiByte only handles 0x41-0x5A"

# Demonstrate functional equivalence after normalization
$normalized = $keyword -replace [char]0x0430, 'a' -replace [char]0x0435, 'e'
Write-Host "After normalization: $normalized"
