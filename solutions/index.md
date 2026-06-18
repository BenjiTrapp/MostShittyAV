---
layout: default
title: All Solutions
permalink: /solutions/
---

<div class="page-header">
  <img src="{{ '/static/logo_transparent.png' | relative_url }}" alt="AMSI Raccoon Lab" class="hero-logo" style="width: 120px;">
  <h1>All Solutions</h1>
  <p>Complete solutions with working code, explanations, and verification steps for all 43 challenges.</p>
</div>

---

## Signature Detection Bypass Solutions

| # | Challenge | Difficulty | Technique |
|---|-----------|:---:|-----------|
| 01 | [String Splitting]({{ '/solutions/01-string-splitting/' | relative_url }}) | Easy | Runtime concatenation |
| 02 | [XOR Encoding]({{ '/solutions/02-xor-encoding/' | relative_url }}) | Easy | Bitwise XOR transformation |
| 03 | [Charcode Construction]({{ '/solutions/03-charcode-construction/' | relative_url }}) | Easy | ASCII integer arrays |
| 04 | [String Reversal]({{ '/solutions/04-string-reversal/' | relative_url }}) | Easy | Reversed string flip |
| 05 | [Environment Variable Abuse]({{ '/solutions/05-environment-variable-abuse/' | relative_url }}) | Medium | OS env var fragments |
| 06 | [ROT13 / Caesar Cipher]({{ '/solutions/06-rot13-caesar-cipher/' | relative_url }}) | Easy | Substitution cipher |
| 07 | [Hex Encoding]({{ '/solutions/07-hex-encoding/' | relative_url }}) | Easy | Hex string decode |
| 08 | [Format String Replace]({{ '/solutions/08-format-string-replace/' | relative_url }}) | Easy | Delimiter insertion/removal |
| 09 | [Type Conversion]({{ '/solutions/09-type-conversion/' | relative_url }}) | Medium | StringBuilder + int array |
| 10 | [UTF-16LE Null Interleaving]({{ '/solutions/10-utf16le-null-interleaving/' | relative_url }}) | Medium | Unicode null byte encoding |
| 11 | [Null Byte Insertion]({{ '/solutions/11-null-byte-insertion/' | relative_url }}) | Medium | Manual null bytes |
| 12 | [Unicode Homoglyph]({{ '/solutions/12-unicode-homoglyph/' | relative_url }}) | Hard | Cyrillic lookalikes |
| 13 | [Zero-Width Characters]({{ '/solutions/13-zero-width-characters/' | relative_url }}) | Hard | Invisible Unicode |
| 14 | [Download Cradle]({{ '/solutions/14-download-cradle/' | relative_url }}) | Easy | Design flaw exploit |

---

## Non-Printable Ratio Bypass Solutions

| # | Challenge | Difficulty | Technique |
|---|-----------|:---:|-----------|
| 15 | [Base64 Encoding]({{ '/solutions/15-base64-encoding/' | relative_url }}) | Easy | 100% printable output |
| 16 | [Ratio Padding]({{ '/solutions/16-ratio-padding/' | relative_url }}) | Easy | Printable byte dilution |
| 17 | [Sub-64 Size Gate]({{ '/solutions/17-sub64-size-gate/' | relative_url }}) | Medium | Minimum size exploit |
| 18 | [Encrypted Payload]({{ '/solutions/18-encrypted-payload/' | relative_url }}) | Medium | AES + Base64 combo |
| 19 | [Archive Container]({{ '/solutions/19-archive-container/' | relative_url }}) | Easy | No-unpack bypass |

---

## Small Executable Bypass Solutions

| # | Challenge | Difficulty | Technique |
|---|-----------|:---:|-----------|
| 20 | [Size Padding]({{ '/solutions/20-size-padding-small-exe/' | relative_url }}) | Easy | Comment padding |
| 21 | [Extension Avoidance]({{ '/solutions/21-extension-avoidance-small/' | relative_url }}) | Easy | Non-suspicious ext |

---

## Extension Heuristic Bypass Solutions

| # | Challenge | Difficulty | Technique |
|---|-----------|:---:|-----------|
| 22 | [Uncommon Extensions]({{ '/solutions/22-uncommon-extensions/' | relative_url }}) | Easy | Unlisted exec extensions |
| 23 | [No Extension]({{ '/solutions/23-no-extension/' | relative_url }}) | Easy | Extensionless files |
| 24 | [Double Extension]({{ '/solutions/24-double-extension/' | relative_url }}) | Easy | Hidden ext trick |
| 25 | [RTLO Unicode]({{ '/solutions/25-rtlo-unicode/' | relative_url }}) | Hard | Visual filename spoofing |
| 26 | [Fullwidth Dot]({{ '/solutions/26-fullwidth-dot/' | relative_url }}) | Hard | Unicode dot bypass |
| 27 | [Trailing Dots/Spaces]({{ '/solutions/27-trailing-dots-spaces/' | relative_url }}) | Medium | NTFS normalization |
| 28 | [NTFS ADS]({{ '/solutions/28-ntfs-ads/' | relative_url }}) | Hard | Alternate Data Streams |
| 29 | [PE Stub]({{ '/solutions/29-pe-stub-no-analysis/' | relative_url }}) | Hard | No PE analysis |
| 30 | [Polyglot File]({{ '/solutions/30-polyglot-file/' | relative_url }}) | Hard | Multi-format files |

---

## AMSI Bypass Solutions

| # | Challenge | Difficulty | Technique |
|---|-----------|:---:|-----------|
| 31 | [AMSI Init Failed]({{ '/solutions/31-amsi-init-failed/' | relative_url }}) | Medium | .NET Reflection flag |
| 32 | [Memory Patch]({{ '/solutions/32-amsi-memory-patch/' | relative_url }}) | Hard | AmsiScanBuffer overwrite |
| 33 | [PowerShell Downgrade]({{ '/solutions/33-powershell-downgrade/' | relative_url }}) | Easy | PSv2 (pre-AMSI) |
| 34 | [Base64 Encoded Command]({{ '/solutions/34-base64-encoded-command/' | relative_url }}) | Easy | -EncodedCommand param |
| 35 | [COM Server Hijacking]({{ '/solutions/35-com-server-hijacking/' | relative_url }}) | Hard | HKCU COM override |
| 36 | [Obfuscated Reflection]({{ '/solutions/36-obfuscated-reflection/' | relative_url }}) | Hard | Dynamic string construction |
| 37 | [CLM Escape]({{ '/solutions/37-clm-escape/' | relative_url }}) | Hard | MSBuild/InstallUtil escape |
| 38 | [Context Corruption]({{ '/solutions/38-context-corruption/' | relative_url }}) | Medium | Null amsiContext |
| 39 | [Chunked Execution]({{ '/solutions/39-chunked-execution/' | relative_url }}) | Medium | Buffer fragmentation |
| 40 | [Fileless Assembly]({{ '/solutions/40-fileless-assembly/' | relative_url }}) | Hard | In-memory .NET load |
| 41 | [DLL Path Hijacking]({{ '/solutions/41-dll-path-hijacking/' | relative_url }}) | Hard | Fake amsi.dll |
| 42 | [WMI Event Subscription]({{ '/solutions/42-wmi-event-subscription/' | relative_url }}) | Hard | Cross-process execution |
| 43 | [ETW Patching]({{ '/solutions/43-etw-patching/' | relative_url }}) | Hard | Telemetry blinding |
