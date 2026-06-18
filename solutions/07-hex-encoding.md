---
title: "Solution 07: Hex Encoding"
challenge_number: 07
difficulty: easy
category: "Signature Detection Bypass"
permalink: /solutions/07-hex-encoding/
---

# Solution: Hex Encoding

[Back to Challenge](../challenges/07-hex-encoding.md)

## Overview

Defeat signature detection by representing the payload string as a hexadecimal string. The file contains only hex characters (0-9, a-f) which are decoded to the actual bytes at runtime.

## Working Code

```powershell
# "malware" in hex: 6d616c77617265
$hex = "6d616c77617265"
$bytes = [byte[]]@(for($i=0; $i -lt $hex.Length; $i+=2) {
    [convert]::ToByte($hex.Substring($i, 2), 16)
})
$word = [System.Text.Encoding]::ASCII.GetString($bytes)
Write-Host $word
```

### Alternate Approaches

```powershell
# Using regex to split hex pairs
$hex = "6d616c77617265"
$pairs = [regex]::Matches($hex, '..') | ForEach-Object { [convert]::ToByte($_.Value, 16) }
$word = [System.Text.Encoding]::ASCII.GetString([byte[]]$pairs)
Write-Host $word

# Using .NET Convert class
$hex = "6d616c77617265"
$bytes = New-Object byte[] ($hex.Length / 2)
for ($i = 0; $i -lt $hex.Length; $i += 2) {
    $bytes[$i/2] = [Convert]::ToByte($hex.Substring($i, 2), 16)
}
$word = [Text.Encoding]::ASCII.GetString($bytes)
Write-Host $word
```

### Multiple Signatures Encoded

```powershell
function ConvertFrom-HexString([string]$hex) {
    $bytes = [byte[]]@(for($i=0; $i -lt $hex.Length; $i+=2) {
        [convert]::ToByte($hex.Substring($i, 2), 16)
    })
    return [System.Text.Encoding]::ASCII.GetString($bytes)
}

# Encoded signatures (all safe to store in file)
$payloads = @{
    target1 = "6d616c77617265"           # malware
    target2 = "7669727573"               # virus
    target3 = "74726f6a616e"             # trojan
    target4 = "72616e736f6d77617265"     # ransomware
    target5 = "64726f70706572"           # dropper
    target6 = "7061796c6f61642e657865"   # payload.exe
}

foreach ($key in $payloads.Keys) {
    Write-Host "${key}: $(ConvertFrom-HexString $payloads[$key])"
}
```

## Why It Works

The hex string `"6d616c77617265"` in the file is stored as the ASCII characters:

```
'6' 'd' '6' '1' '6' 'c' '7' '7' '6' '1' '7' '2' '6' '5'
0x36 0x64 0x36 0x31 0x36 0x63 0x37 0x37 0x36 0x31 0x37 0x32 0x36 0x35
```

The scanner searches for:
```
'm'  'a'  'l'  'w'  'a'  'r'  'e'
0x6D 0x61 0x6C 0x77 0x61 0x72 0x65
```

These byte sequences have zero overlap. The hex representation uses only characters in the ranges `0x30-0x39` (digits 0-9) and `0x61-0x66` (letters a-f). The scanner sees alphanumeric text, not the binary values those hex pairs represent.

The conversion from hex string to bytes is a runtime interpretation that requires executing the `[Convert]::ToByte()` logic - something a static byte scanner cannot do.

## How to Verify

1. Save the code:
   ```powershell
   @'
   $hex = "6d616c77617265"
   $bytes = [byte[]]@(for($i=0;$i -lt $hex.Length;$i+=2){[convert]::ToByte($hex.Substring($i,2),16)})
   $word = [System.Text.Encoding]::ASCII.GetString($bytes)
   Write-Host $word
   '@ | Set-Content "test_hex.ps1"
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_hex.ps1
   ```

3. Expected result: **No detection** - hex characters are just alphanumeric text.

4. Execute to confirm:
   ```powershell
   powershell -File test_hex.ps1
   # Output: malware
   ```
