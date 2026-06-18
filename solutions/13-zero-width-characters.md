---
title: "Solution 13: Zero-Width Character Insertion"
challenge_number: 13
difficulty: hard
category: "Signature Detection Bypass"
permalink: /solutions/13-zero-width-characters/
---

# Solution: Zero-Width Character Insertion

[Back to Challenge](../challenges/13-zero-width-characters.md)

## Overview

Defeat signature detection by inserting Unicode Zero-Width Space characters (U+200B) between each letter. These characters are invisible when rendered but add 3 UTF-8 bytes (`E2 80 8B`) between each signature character, completely breaking contiguous byte matching.

## Working Code

```powershell
# Insert Zero-Width Space (U+200B) between each character
$zwsp = [char]0x200B
$word = "m${zwsp}a${zwsp}l${zwsp}w${zwsp}a${zwsp}r${zwsp}e"
Write-Host $word
Write-Host "Length: $($word.Length)"  # 13 (7 chars + 6 ZWSP)
```

### Alternate Approaches

```powershell
# Build with explicit char insertion
$zwsp = [char]0x200B
$chars = @('m','a','l','w','a','r','e')
$word = ($chars -join $zwsp)
Write-Host "Word: $word"

# Using other zero-width characters
$zwnj = [char]0x200C  # Zero-Width Non-Joiner
$zwj  = [char]0x200D  # Zero-Width Joiner
$wj   = [char]0x2060  # Word Joiner

# Any of these work
$word1 = "m${zwnj}a${zwnj}l${zwnj}w${zwnj}a${zwnj}r${zwnj}e"
$word2 = "m${zwj}a${zwj}l${zwj}w${zwj}a${zwj}r${zwj}e"
$word3 = "m${wj}a${wj}l${wj}w${wj}a${wj}r${wj}e"

Write-Host $word1
Write-Host $word2
Write-Host $word3

# Strip zero-width chars to get clean string
$clean = $word1 -replace "[\u200B-\u200D\u2060]", ""
Write-Host "Clean: $clean"
```

### Function for Encoding/Decoding

```powershell
function Add-ZeroWidth([string]$text) {
    $zwsp = [char]0x200B
    return ($text.ToCharArray() -join $zwsp)
}

function Remove-ZeroWidth([string]$text) {
    return $text -replace "[\u200B-\u200D\u2060\uFEFF]", ""
}

# Encode (for embedding in payload files)
$encoded = Add-ZeroWidth "malware"
Write-Host "Encoded length: $($encoded.Length)"  # 13

# Decode at runtime
$decoded = Remove-ZeroWidth $encoded
Write-Host "Decoded: $decoded"  # malware
```

### Applied to Other Signatures

```powershell
$zwsp = [char]0x200B
$signatures = @(
    "trojan",
    "virus",
    "ransomware",
    "dropper"
)

foreach ($sig in $signatures) {
    $hidden = ($sig.ToCharArray() -join $zwsp)
    Write-Host "Hidden '$sig': length $($hidden.Length) (original: $($sig.Length))"
}
```

## Why It Works

Zero-Width Space (U+200B) encodes in UTF-8 as three bytes: `E2 80 8B`. When inserted between each character of "malware":

**Original "malware" in UTF-8:**
```
6D 61 6C 77 61 72 65
m  a  l  w  a  r  e
```

**With ZWSP between each character:**
```
6D E2808B 61 E2808B 6C E2808B 77 E2808B 61 E2808B 72 E2808B 65
m  [ZWSP] a  [ZWSP] l  [ZWSP] w  [ZWSP] a  [ZWSP] r  [ZWSP] e
```

The scanner's contiguous matching expects `6D` to be immediately followed by `61`. Instead, it finds `6D E2 80 8B 61...`. The three bytes `E2 80 8B` are not in the ASCII range the scanner processes for letter matching, and they break the expected contiguous sequence.

Key advantages of this technique:
- The text **looks identical** to the naked eye in most editors and terminals
- Zero-width characters are legitimate Unicode - not suspicious binary data
- Each ZWSP adds 3 bytes of disruption between signature characters

## How to Verify

1. Save the code (UTF-8 encoding required):
   ```powershell
   $code = @'
   $zwsp = [char]0x200B
   $word = "m${zwsp}a${zwsp}l${zwsp}w${zwsp}a${zwsp}r${zwsp}e"
   Write-Host "Word: $word"
   $clean = $word -replace "[\u200B]", ""
   Write-Host "Clean: $clean"
   '@
   [System.IO.File]::WriteAllText("test_zwsp.ps1", $code, [System.Text.UTF8Encoding]::new($false))
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_zwsp.ps1
   ```

3. Expected result: **No detection** - zero-width bytes disrupt all signature patterns.

4. Execute to confirm:
   ```powershell
   powershell -File test_zwsp.ps1
   # Output: Word: malware  (looks normal due to zero-width chars being invisible)
   # Output: Clean: malware
   ```

5. Verify the disruption visually:
   ```powershell
   $zwsp = [char]0x200B
   $word = "m${zwsp}alware"
   $bytes = [System.Text.Encoding]::UTF8.GetBytes($word)
   Write-Host "Bytes: $($bytes | ForEach-Object { '{0:X2}' -f $_ })"
   # Shows: 6D E2 80 8B 61 6C 77 61 72 65
   ```
