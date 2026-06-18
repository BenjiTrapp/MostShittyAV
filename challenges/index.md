---
layout: default
title: All Challenges
permalink: /challenges/
---

<div class="page-header">
  <img src="{{ '/static/logo_transparent.png' | relative_url }}" alt="AMSI Raccoon Lab" class="hero-logo" style="width: 120px;">
  <h1>All Challenges</h1>
  <p>43 bypass challenges across 5 categories. Each challenge targets a specific weakness in the scanner's detection engine.</p>
</div>

---

## Signature Detection Bypass
{: #signature-detection-bypass}

Defeat the scanner's static string matching engine that searches for known malware signatures as contiguous byte sequences.

<div class="card-grid">
  <a href="{{ '/challenges/01-string-splitting/' | relative_url }}" class="card">
    <div class="card-title">#01 String Splitting</div>
    <div class="card-description">Fragment signature strings into runtime-concatenated parts.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/02-xor-encoding/' | relative_url }}" class="card">
    <div class="card-title">#02 XOR Encoding</div>
    <div class="card-description">Use bitwise XOR to transform signature bytes beyond recognition.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/03-charcode-construction/' | relative_url }}" class="card">
    <div class="card-title">#03 Charcode Construction</div>
    <div class="card-description">Build strings from numeric ASCII character codes.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/04-string-reversal/' | relative_url }}" class="card">
    <div class="card-title">#04 String Reversal</div>
    <div class="card-description">Store signatures backwards; reverse at runtime.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/05-environment-variable-abuse/' | relative_url }}" class="card">
    <div class="card-title">#05 Environment Variable Abuse</div>
    <div class="card-description">Hide string fragments in OS environment variables.</div>
    <div class="card-meta"><span class="badge badge-medium">Medium</span></div>
  </a>
  <a href="{{ '/challenges/06-rot13-caesar-cipher/' | relative_url }}" class="card">
    <div class="card-title">#06 ROT13 / Caesar Cipher</div>
    <div class="card-description">Apply classical substitution ciphers to evade matching.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/07-hex-encoding/' | relative_url }}" class="card">
    <div class="card-title">#07 Hex Encoding</div>
    <div class="card-description">Represent signature bytes as hexadecimal digit strings.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/08-format-string-replace/' | relative_url }}" class="card">
    <div class="card-title">#08 Format String Replace</div>
    <div class="card-description">Insert noise characters and strip them at runtime.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/09-type-conversion/' | relative_url }}" class="card">
    <div class="card-title">#09 Type Conversion</div>
    <div class="card-description">Abuse .NET type system and StringBuilder to assemble strings.</div>
    <div class="card-meta"><span class="badge badge-medium">Medium</span></div>
  </a>
  <a href="{{ '/challenges/10-utf16le-null-interleaving/' | relative_url }}" class="card">
    <div class="card-title">#10 UTF-16LE Null Interleaving</div>
    <div class="card-description">Exploit Unicode encoding differences to break byte matching.</div>
    <div class="card-meta"><span class="badge badge-medium">Medium</span></div>
  </a>
  <a href="{{ '/challenges/11-null-byte-insertion/' | relative_url }}" class="card">
    <div class="card-title">#11 Null Byte Insertion</div>
    <div class="card-description">Insert invisible null bytes to split contiguous patterns.</div>
    <div class="card-meta"><span class="badge badge-medium">Medium</span></div>
  </a>
  <a href="{{ '/challenges/12-unicode-homoglyph/' | relative_url }}" class="card">
    <div class="card-title">#12 Unicode Homoglyph</div>
    <div class="card-description">Replace ASCII with visually identical Unicode characters.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
  <a href="{{ '/challenges/13-zero-width-characters/' | relative_url }}" class="card">
    <div class="card-title">#13 Zero-Width Characters</div>
    <div class="card-description">Insert invisible Unicode characters that break byte sequences.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
  <a href="{{ '/challenges/14-download-cradle/' | relative_url }}" class="card">
    <div class="card-title">#14 Download Cradle</div>
    <div class="card-description">Exploit the scanner's warning-only pattern check design flaw.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
</div>

---

## Non-Printable Ratio Bypass
{: #non-printable-ratio-bypass}

Defeat the scanner's non-printable byte analysis that flags files with >40% non-printable content (for files >= 64 bytes).

<div class="card-grid">
  <a href="{{ '/challenges/15-base64-encoding/' | relative_url }}" class="card">
    <div class="card-title">#15 Base64 Encoding</div>
    <div class="card-description">Convert binary to 100% printable ASCII characters.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/16-ratio-padding/' | relative_url }}" class="card">
    <div class="card-title">#16 Ratio Padding</div>
    <div class="card-description">Dilute the non-printable ratio with junk printable bytes.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/17-sub64-size-gate/' | relative_url }}" class="card">
    <div class="card-title">#17 Sub-64 Size Gate</div>
    <div class="card-description">Exploit the 64-byte minimum file size requirement.</div>
    <div class="card-meta"><span class="badge badge-medium">Medium</span></div>
  </a>
  <a href="{{ '/challenges/18-encrypted-payload/' | relative_url }}" class="card">
    <div class="card-title">#18 Encrypted Payload</div>
    <div class="card-description">Use encryption combined with encoding to pass all checks.</div>
    <div class="card-meta"><span class="badge badge-medium">Medium</span></div>
  </a>
  <a href="{{ '/challenges/19-archive-container/' | relative_url }}" class="card">
    <div class="card-title">#19 Archive Container</div>
    <div class="card-description">Hide payloads inside archive formats the scanner can't unpack.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
</div>

---

## Small Executable Bypass
{: #small-executable-bypass}

Circumvent the check that flags files smaller than 32 bytes with suspicious extensions.

<div class="card-grid">
  <a href="{{ '/challenges/20-size-padding-small-exe/' | relative_url }}" class="card">
    <div class="card-title">#20 Size Padding</div>
    <div class="card-description">Add non-functional content to exceed the 32-byte threshold.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/21-extension-avoidance-small/' | relative_url }}" class="card">
    <div class="card-title">#21 Extension Avoidance</div>
    <div class="card-description">Break the dual-condition check by using a non-suspicious extension.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
</div>

---

## Extension Heuristic Bypass
{: #extension-heuristic-bypass}

Exploit weaknesses in the scanner's extension-based file type detection.

<div class="card-grid">
  <a href="{{ '/challenges/22-uncommon-extensions/' | relative_url }}" class="card">
    <div class="card-title">#22 Uncommon Extensions</div>
    <div class="card-description">Use executable extensions not on the hardcoded list.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/23-no-extension/' | relative_url }}" class="card">
    <div class="card-title">#23 No Extension</div>
    <div class="card-description">Exploit rfind('.') returning -1 with extensionless files.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/24-double-extension/' | relative_url }}" class="card">
    <div class="card-title">#24 Double Extension</div>
    <div class="card-description">Social engineering via hidden extension display behavior.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/25-rtlo-unicode/' | relative_url }}" class="card">
    <div class="card-title">#25 RTLO Unicode</div>
    <div class="card-description">Right-to-Left Override to visually spoof filenames.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
  <a href="{{ '/challenges/26-fullwidth-dot/' | relative_url }}" class="card">
    <div class="card-title">#26 Fullwidth Dot</div>
    <div class="card-description">Unicode fullwidth period invisible to ASCII dot search.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
  <a href="{{ '/challenges/27-trailing-dots-spaces/' | relative_url }}" class="card">
    <div class="card-title">#27 Trailing Dots/Spaces</div>
    <div class="card-description">Exploit NTFS filename normalization behavior.</div>
    <div class="card-meta"><span class="badge badge-medium">Medium</span></div>
  </a>
  <a href="{{ '/challenges/28-ntfs-ads/' | relative_url }}" class="card">
    <div class="card-title">#28 NTFS ADS</div>
    <div class="card-description">Hide payloads in Alternate Data Streams the scanner ignores.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
  <a href="{{ '/challenges/29-pe-stub-no-analysis/' | relative_url }}" class="card">
    <div class="card-title">#29 PE Stub (No Analysis)</div>
    <div class="card-description">Craft a PE executable that passes without structural checks.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
  <a href="{{ '/challenges/30-polyglot-file/' | relative_url }}" class="card">
    <div class="card-title">#30 Polyglot File</div>
    <div class="card-description">Create files valid in multiple formats simultaneously.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
</div>

---

## AMSI Bypass
{: #amsi-bypass}

Disable or circumvent the Windows Antimalware Scan Interface through runtime manipulation.

<div class="card-grid">
  <a href="{{ '/challenges/31-amsi-init-failed/' | relative_url }}" class="card">
    <div class="card-title">#31 AMSI Init Failed</div>
    <div class="card-description">Manipulate PowerShell's internal AMSI initialization flag.</div>
    <div class="card-meta"><span class="badge badge-medium">Medium</span></div>
  </a>
  <a href="{{ '/challenges/32-amsi-memory-patch/' | relative_url }}" class="card">
    <div class="card-title">#32 Memory Patch</div>
    <div class="card-description">Overwrite AmsiScanBuffer to always return clean.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
  <a href="{{ '/challenges/33-powershell-downgrade/' | relative_url }}" class="card">
    <div class="card-title">#33 PowerShell Downgrade</div>
    <div class="card-description">Use PSv2 which predates AMSI entirely.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/34-base64-encoded-command/' | relative_url }}" class="card">
    <div class="card-title">#34 Base64 Encoded Command</div>
    <div class="card-description">Encode payloads for -EncodedCommand to evade file scanning.</div>
    <div class="card-meta"><span class="badge badge-easy">Easy</span></div>
  </a>
  <a href="{{ '/challenges/35-com-server-hijacking/' | relative_url }}" class="card">
    <div class="card-title">#35 COM Server Hijacking</div>
    <div class="card-description">Redirect AMSI to a dummy provider via HKCU COM override.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
  <a href="{{ '/challenges/36-obfuscated-reflection/' | relative_url }}" class="card">
    <div class="card-title">#36 Obfuscated Reflection</div>
    <div class="card-description">Achieve amsiInitFailed without detectable strings in the script.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
  <a href="{{ '/challenges/37-clm-escape/' | relative_url }}" class="card">
    <div class="card-title">#37 CLM Escape</div>
    <div class="card-description">Escape Constrained Language Mode before bypassing AMSI.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
  <a href="{{ '/challenges/38-context-corruption/' | relative_url }}" class="card">
    <div class="card-title">#38 Context Corruption</div>
    <div class="card-description">Null the AMSI context handle to force scan failure.</div>
    <div class="card-meta"><span class="badge badge-medium">Medium</span></div>
  </a>
  <a href="{{ '/challenges/39-chunked-execution/' | relative_url }}" class="card">
    <div class="card-title">#39 Chunked Execution</div>
    <div class="card-description">Split payload across multiple independently-scanned buffers.</div>
    <div class="card-meta"><span class="badge badge-medium">Medium</span></div>
  </a>
  <a href="{{ '/challenges/40-fileless-assembly/' | relative_url }}" class="card">
    <div class="card-title">#40 Fileless Assembly</div>
    <div class="card-description">Load .NET assemblies directly into memory without disk I/O.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
  <a href="{{ '/challenges/41-dll-path-hijacking/' | relative_url }}" class="card">
    <div class="card-title">#41 DLL Path Hijacking</div>
    <div class="card-description">Plant a fake amsi.dll in the DLL search path.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
  <a href="{{ '/challenges/42-wmi-event-subscription/' | relative_url }}" class="card">
    <div class="card-title">#42 WMI Event Subscription</div>
    <div class="card-description">Execute in wmiprvse.exe via WMI Living-off-the-Land.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
  <a href="{{ '/challenges/43-etw-patching/' | relative_url }}" class="card">
    <div class="card-title">#43 ETW Patching</div>
    <div class="card-description">Blind all telemetry by patching EtwEventWrite.</div>
    <div class="card-meta"><span class="badge badge-hard">Hard</span></div>
  </a>
</div>
