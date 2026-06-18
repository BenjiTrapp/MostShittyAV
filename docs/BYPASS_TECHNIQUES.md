# Bypass-Techniken & Testcases

Dieses Dokument beschreibt alle implementierten Erkennungsmethoden des MostShittyAV-Scanners,
die zugehoerigen Testcases und die Bypass-Szenarien mit einer Erklaerung, **warum** jede Technik funktioniert.

---

## Uebersicht: Erkennungs-Engine

Der Scanner implementiert sechs Pruefungen:

| # | Methode | Schwelle | Aktion |
|---|---------|----------|--------|
| 1 | Signatur-Scan | Enthalt bekannten String | MALICIOUS |
| 2 | Extension-Heuristik | Verdaechtige Dateiendung | WARNING (blockiert nicht!) |
| 3 | Non-Printable-Ratio | > 40% nicht-druckbare Bytes (bei >= 64 Bytes) | MALICIOUS |
| 4 | Small-Executable-Check | < 32 Bytes + verdaechtige Extension | MALICIOUS |
| 5 | Suspicious-Pattern-Check | Verdaechtige Script-Patterns (IEX, WebClient, ...) | WARNING |
| 6 | Entropy-Check | Shannon-Entropie > 7.2 bits/byte (bei >= 128 Bytes) | WARNING |

---

## 1. Signatur-Erkennung

### Wie es funktioniert

Der Scanner sucht case-insensitive nach folgenden Strings im Dateiinhalt:

```nim
const signatures = [
  "malware", "virus", "trojan", "evil_payload",
  "dropper", "ransomware", "payload.exe"
]
```

Die gesamte Datei wird in Kleinbuchstaben konvertiert und dann per `find()` nach jedem Signatur-String durchsucht.

### Testcases (Erkennung)

| Datei | Inhalt | Erwartetes Ergebnis |
|-------|--------|---------------------|
| `tests/02_signature/malware.ps1` | Enthalt "malware" als String | MALICIOUS |
| `tests/02_signature/trojan_sample.txt` | Enthalt "Trojan" | MALICIOUS |
| `tests/02_signature/infected.txt` | Enthalt "MALWARE" | MALICIOUS |

### Bypass-Szenarien

#### 1.1 String-Splitting (Konkatenation)

**Testdatei:** `tests/02_signature/malware_bypass.ps1`

```powershell
Write-Host "mal" + "ware.ps1 executed";
```

**Warum es funktioniert:**
Der Scanner liest die Datei als Rohtext und sucht nach dem zusammenhaengenden String `"malware"`.
Wenn der String zur Laufzeit durch Konkatenation zusammengesetzt wird (`"mal" + "ware"`),
existiert er nie als zusammenhaengender String in der Datei. Der Scanner fuehrt keine
Code-Interpretation oder Deobfuskation durch -- er sieht nur die statischen Bytes.

**Reale Relevanz:** Dies ist eine der grundlegendsten Evasion-Techniken gegen signaturbasierte
Scanner. Echte Malware nutzt String-Obfuskation, XOR-Verschluesselung oder dynamische
String-Generierung, um Signaturen zu umgehen.

#### 1.2 XOR-Encoding

**Testdatei:** `tests/02_signature/bypass_xor_encoding.ps1`

```powershell
$key = 0x42
$encoded = @(0x2F, 0x23, 0x2E, 0x35, 0x23, 0x30, 0x27)  # "malware" XOR 0x42
$decoded = -join ($encoded | ForEach-Object { [char]($_ -bxor $key) })
```

**Warum es funktioniert:**
XOR-Verschluesselung transformiert jeden Byte-Wert der Signatur. Das Ergebnis (`0x2F, 0x23, ...`)
hat keinerlei Aehnlichkeit mit dem Original-String "malware". Der Scanner muesste jede moegliche
XOR-Key-Kombination (0x01-0xFF) durchprobieren, um die verschluesselten Signaturen zu finden --
das tut er nicht.

**Reale Relevanz:** XOR ist der Standard-Obfuskator in Malware. Viele Packer (UPX, Themida)
nutzen XOR oder AES um Payloads zu verschluesseln. Echte AV-Engines nutzen Emulation und
Sandbox-Execution um den entschluesselten Code zu analysieren.

#### 1.3 Character-Code-Konstruktion

**Testdatei:** `tests/02_signature/bypass_charcode.ps1`

```powershell
$payload = [char]109 + [char]97 + [char]108 + [char]119 + [char]97 + [char]114 + [char]101
```

**Warum es funktioniert:**
Der String wird aus einzelnen numerischen ASCII-Werten zusammengebaut. In der Datei stehen
nur Zahlen (109, 97, 108...) -- nie der zusammenhaengende String. Der Scanner muesste
Typkonvertierungen und arithmetische Operationen interpretieren, um die Signatur zu erkennen.

**Reale Relevanz:** JavaScript-Malware nutzt diese Technik extensiv (`String.fromCharCode()`).
In PowerShell und Python ist Character-Construction ein gaengiges Obfuskations-Pattern.

#### 1.4 String-Reversal

**Testdatei:** `tests/02_signature/bypass_reversal.ps1`

```powershell
$reversed = "erawlam"
$payload = -join ($reversed[-1..-($reversed.Length)])
```

**Warum es funktioniert:**
Die Signatur wird rueckwaerts gespeichert. "erawlam" matcht keinen Forward-Scan nach "malware".
Zur Laufzeit wird der String umgedreht. Der Scanner muesste jede Signatur auch rueckwaerts
pruefen -- das verdoppelt den Aufwand und erzeugt False Positives.

**Reale Relevanz:** Einfach, aber effektiv gegen Regex-basierte Scanner die nur in eine
Richtung matchen. Oft kombiniert mit anderen Techniken.

#### 1.5 Environment-Variable-Abuse

**Testdatei:** `tests/02_signature/bypass_env_vars.ps1`

```powershell
$env:__P1 = "mal"
$env:__P2 = "ware"
$result = $env:__P1 + $env:__P2
```

**Warum es funktioniert:**
Die Signatur-Teile werden in Umgebungsvariablen gespeichert. Der Scanner sieht nur
Variablenzuweisungen mit harmlosen Strings ("mal", "ware"). Erst zur Laufzeit werden die
Variablen aufgeloest und konkateniert. Statische Analyse kann Umgebungsvariablen nicht
aufloesen, da ihr Wert von der Laufzeitumgebung abhaengt.

**Reale Relevanz:** Angreifer nutzen Umgebungsvariablen, Registry-Werte und WMI-Properties
als Speicher fuer Payload-Fragmente ("Living off the Land").

#### 1.6 ROT13 / Caesar-Chiffre

**Testdatei:** `tests/02_signature/bypass_rot13.ps1`

```powershell
$encoded = "znyJner"  # "malWare" in ROT13
```

**Warum es funktioniert:**
ROT13 verschiebt jeden Buchstaben um 13 Positionen. "m" wird zu "z", "a" zu "n", etc.
Der resultierende String "znyJner" hat keine Aehnlichkeit mit "malWare". Der Scanner
muesste alle 25 Caesar-Verschiebungen pruefen.

**Reale Relevanz:** Einfache Substitutions-Chiffren sind in Script-Malware verbreitet.
Hoeherwertige Varianten nutzen polyalphabetische Chiffren (Vigenere) oder Custom-Alphabete.

#### 1.7 Hex-Encoding

**Testdatei:** `tests/02_signature/bypass_hex_encoding.ps1`

```powershell
$hexPayload = "6d616c77617265"  # "malware" in hex
$bytes = [Convert]::ToByte($hexPayload.Substring($i, 2), 16)
```

**Warum es funktioniert:**
Die Signatur wird als Hex-String gespeichert. "6d616c77617265" ist fuer den Scanner
ein bedeutungsloser alphanumerischer String. Erst die Laufzeit-Konvertierung ergibt "malware".

**Reale Relevanz:** Hex-Encoding ist Standard in Shellcode-Delivery. Metasploit, Cobalt Strike
und andere Frameworks liefern Payloads als Hex-Arrays aus.

#### 1.8 Format-String / Replace

**Testdatei:** `tests/02_signature/bypass_format_string.ps1`

```powershell
$template = "m_a_l_w_a_r_e"
$payload = $template -replace "_", ""
```

**Warum es funktioniert:**
Trennzeichen zwischen den Buchstaben verhindern den Signatur-Match. Der Scanner findet
"m_a_l_w_a_r_e" -- nicht "malware". Erst die Replace-Operation entfernt die Trennzeichen.

**Reale Relevanz:** String-Manipulation via Replace, Split/Join oder Regex ist eine der
haeufigsten Obfuskationstechniken in PowerShell-Malware (Invoke-Obfuscation).

#### 1.9 Type-Conversion (Integer-Array)

**Testdatei:** `tests/02_signature/bypass_type_conversion.ps1`

```powershell
$intArray = @(109, 97, 108, 119, 97, 114, 101)
$sb = New-Object System.Text.StringBuilder
$intArray | ForEach-Object { [void]$sb.Append([char]$_) }
```

**Warum es funktioniert:**
Identisch mit Char-Code-Konstruktion, aber nutzt StringBuilder fuer die Assemblierung.
Der Scanner sieht ein Integer-Array und StringBuilder-Aufrufe -- keine Signatur.
Demonstriert, dass es dutzende Wege gibt, denselben Bypass zu implementieren.

---

## 2. Extension-Heuristik

### Wie es funktioniert

Der Scanner extrahiert die Dateiendung mit `rfind('.')` und prueft gegen eine Liste:

```nim
const suspicious = [
  ".exe", ".dll", ".bat", ".cmd", ".sh",
  ".ps1", ".scr", ".js", ".vbs", ".jar", ".lnk"
]
```

**Wichtig:** Diese Pruefung gibt nur eine Warnung aus, blockiert aber NICHT (`discard`).

### Testcases (Erkennung)

| Datei | Extension | Erwartetes Ergebnis |
|-------|-----------|---------------------|
| `tests/04_extension/extension_detected.exe` | `.exe` | WARNING (nicht blockiert) |
| `tests/04_extension/malware.exe` | `.exe` | WARNING |
| `tests/04_extension/VIRUS.EXE` | `.EXE` -> `.exe` | WARNING |
| `tests/04_extension/Malware.BaT` | `.BaT` -> `.bat` | WARNING |
| `tests/04_extension/script.Ps1` | `.Ps1` -> `.ps1` | WARNING |

### Bypass-Szenarien

#### 2.1 Unbekannte ausfuehrbare Endungen

**Testdateien:**
- `tests/04_extension/help.hta`
- `tests/04_extension/legacy.com`
- `tests/04_extension/component.wsf`
- `tests/04_extension/old.pif`

**Warum es funktioniert:**
Die Extensions `.hta`, `.com`, `.wsf` und `.pif` sind unter Windows vollstaendig ausfuehrbar,
stehen aber nicht in der `suspicious`-Liste des Scanners. Windows fuehrt diese Dateien ueber
registrierte Handler aus:
- `.hta` -- HTML Application (mshta.exe), kann beliebigen VBScript/JScript ausfuehren
- `.com` -- DOS-Executable-Format, wird direkt ausgefuehrt
- `.wsf` -- Windows Script File, unterstuetzt VBScript/JScript
- `.pif` -- Program Information File, Legacy-Format das Programme starten kann

**Reale Relevanz:** AV-Produkte muessen hunderte von ausfuehrbaren Formaten kennen.
Jede fehlende Endung ist ein potenzieller Bypass. Angreifer nutzen gezielt exotische
Dateiformate die vom AV nicht geprueft werden.

#### 2.2 Keine Dateiendung

**Testdateien:**
- `tests/04_extension/malware_no_ext`
- `tests/04_extension/suspicious_no_ext`

**Warum es funktioniert:**
Ohne Punkt im Dateinamen gibt `rfind('.')` -1 zurueck, und die Extension wird als
leerer String `""` interpretiert. Ein leerer String ist nicht in der `suspicious`-Liste.
Unter Linux/macOS ist die Dateiendung ohnehin irrelevant fuer die Ausfuehrbarkeit --
dort zaehlt das Execute-Bit. Unter Windows kann eine Datei ohne Endung ueber
`cmd /c dateiname` oder durch explizite Programm-Zuordnung ausgefuehrt werden.

**Reale Relevanz:** Viele Malware-Dropper speichern Payloads ohne Endung und benennen
sie erst unmittelbar vor der Ausfuehrung um.

#### 2.3 Doppelte Endungen (Double Extension)

**Testdateien:**
- `tests/04_extension/document.pdf.exe` -- Sieht fuer User aus wie PDF
- `tests/04_extension/image.jpg.bat` -- Sieht aus wie Bild
- `tests/04_extension/readme.txt.ps1` -- Sieht aus wie Textdatei

**Warum es funktioniert:**
Der Scanner nutzt `rfind('.')` und findet damit die **letzte** Endung korrekt (`.exe`, `.bat`, `.ps1`).
Allerdings: In Windows Explorer werden bekannte Endungen standardmaessig ausgeblendet.
Ein User sieht nur `document.pdf` und glaubt, es sei ein PDF. Der Scanner warnt zwar
(Extension wird erkannt), aber blockiert nicht -- und fuer Social Engineering reicht das.

**Reale Relevanz:** Double Extensions sind eine der aeltesten Social-Engineering-Techniken.
Sie funktionieren weil Windows Explorer standardmaessig Endungen versteckt und Nutzer
dem scheinbaren Dateityp vertrauen.

#### 2.4 RTLO (Right-to-Left Override) Unicode

**Testdateien:**
- `tests/04_extension/rtlo_bypass.sh` (Dateiname enthalt U+202E)
- `tests/04_extension/rtlo_generator.py` (Generator-Script)

**Warum es funktioniert:**
Das Unicode-Zeichen U+202E (Right-to-Left Override) kehrt die Darstellungsrichtung
aller folgenden Zeichen um. Ein Dateiname wie `harmloshs.exe` mit RTLO vor `hs.exe`
wird angezeigt als `harmloexe.sh`. Der Scanner sieht den echten Dateinamen mit dem
Unicode-Zeichen und kann die Extension falsch parsen, da der Punkt visuell an einer
anderen Stelle erscheint als im Bytestream.

**Reale Relevanz:** RTLO-Angriffe wurden in der Wildnis beobachtet (u.a. bei Phishing).
Moderne Betriebssysteme warnen teilweise vor RTLO in Dateinamen, aber aeltere Systeme
und viele Dateimanager zeigen den manipulierten Namen an.

#### 2.5 Unicode Fullwidth-Punkt

**Testdatei:** `tests/04_extension/unicode_fullwidth_dot.exe`

Original-Dateiname: `file．exe` (mit U+FF0E statt normalem Punkt)

**Warum es funktioniert:**
Der Scanner sucht mit `rfind('.')` nach dem ASCII-Punkt (U+002E). Der Fullwidth-Punkt
(U+FF0E) ist visuell identisch, aber ein voellig anderes Byte. Dadurch findet der Scanner
keinen Punkt und interpretiert die Datei als "ohne Endung". Das Betriebssystem koennte
den Fullwidth-Punkt je nach Filesystem-Implementierung anders behandeln.

**Reale Relevanz:** Unicode-Normalisierungsprobleme sind eine bekannte Angriffskategorie.
Webserver, Dateisysteme und Scanner die Unicode nicht korrekt normalisieren, sind anfaellig
fuer Homoglyph-Angriffe und Unicode-Verwechslungen.

#### 2.6 Trailing Dots/Spaces

**Testdateien:**
- `tests/04_extension/trojan.exe` (Original: `trojan.exe.`)
- `tests/04_extension/payload.bat` (Original: `payload.bat...`)
- `tests/04_extension/script.bat` (Original: `script.bat  `)

**Warum es funktioniert:**
Windows NTFS entfernt automatisch nachgestellte Punkte und Leerzeichen beim Erstellen
von Dateien. `trojan.exe.` wird zu `trojan.exe`. Der Angriff zielt darauf ab, dass der
Scanner den Dateinamen *vor* der OS-Normalisierung sieht und die Extension falsch parst
(z.B. Extension = `".exe."` statt `".exe"`). In der Praxis normalisiert Windows den Namen
aber bereits, sodass dieser Bypass nur bei Scannern greift, die den Pfad-String vor dem
Filesystem-Zugriff pruefen.

---

## 3. Non-Printable Byte Ratio

### Wie es funktioniert

Der Scanner zaehlt Bytes ausserhalb des druckbaren ASCII-Bereichs (< 9, 14-31, > 126):

```nim
proc nonPrintableRatioBytes(content: seq[byte]): float =
  for b in content:
    if b < 9 or (b > 13 and b < 32) or b > 126:
      inc(nonPrintable)
  return nonPrintable.float / content.len.float
```

Schwellenwert: > 40% nicht-druckbare Bytes bei Dateien >= 64 Bytes = MALICIOUS.

### Testcases (Erkennung)

| Datei | Non-Printable Ratio | Erwartetes Ergebnis |
|-------|---------------------|---------------------|
| `tests/03_encoding/utf16.txt` | ~50% (BOM + Null-Bytes) | MALICIOUS |
| `tests/03_encoding/packed.bin` | ~75% (Zufallsbytes) | MALICIOUS |
| `tests/03_encoding/mixed.bin` | > 40% (gemischt) | MALICIOUS |

### Bypass-Szenarien

#### 3.1 Base64-Encoding

**Testdatei:** `tests/03_encoding/utf16_bypass.txt`

**Warum es funktioniert:**
Base64 konvertiert beliebige Binaerdaten in druckbare ASCII-Zeichen (A-Z, a-z, 0-9, +, /).
Eine Datei die zu 100% aus nicht-druckbaren Bytes besteht, hat nach Base64-Encoding eine
Non-Printable-Ratio von 0%. Der Scanner prueft nur den statischen Dateiinhalt und erkennt
nicht, dass der Inhalt kodiert ist. Zur Laufzeit kann ein Decoder den originalen
Schadcode wiederherstellen.

**Reale Relevanz:** Base64 ist die Standard-Technik fuer Payload-Delivery in PowerShell
(`[Convert]::FromBase64String()`), E-Mail-Anhaengen und Web-Exploits. Viele AV-Produkte
dekodieren Base64 mittlerweile vor der Analyse (Multi-Layer-Scanning).

#### 3.2 Ratio-Manipulation (Padding)

**Testdatei:** `tests/03_encoding/mixed_bypass.bin`

**Warum es funktioniert:**
Wenn die Schwelle bei 40% liegt, muss ein Angreifer nur genuegend druckbare Bytes
einfuegen, um die Ratio unter den Schwellenwert zu druecken. Bei einer 100-Byte-Payload
mit 80% nicht-druckbaren Bytes genuegt es, 120 Bytes druckbaren "Junk" anzuhaengen
(80/220 = 36% < 40%). Der Schadcode bleibt funktional, wird aber durch die Verwaeusserung
nicht mehr erkannt.

**Reale Relevanz:** Padding/Junk-Insertion ist eine klassische AV-Evasion-Technik.
Echte Packer wie UPX erzeugen Code-Sections mit variablen Ratios. Moderne AV-Engines
nutzen deshalb Section-basierte Analyse statt einer globalen Ratio.

---

## 4. Small-Executable-Check

### Wie es funktioniert

```nim
if self.content.len < 32 and isSuspiciousExtension(self.ext):
  # MALICIOUS
```

Dateien unter 32 Bytes mit verdaechtiger Endung werden als boeswillig eingestuft.

### Testcases (Erkennung)

| Datei | Groesse | Extension | Erwartetes Ergebnis |
|-------|---------|-----------|---------------------|
| `tests/05_small_executable/tiny.bat` | ~20 Bytes | `.bat` | MALICIOUS |

### Bypass-Szenarien

#### 4.1 Groesse erhoehen (Padding)

**Warum es funktioniert:**
Einfach 32+ Bytes an Kommentaren oder Whitespace zur Datei hinzufuegen:
```batch
@echo off
REM ========================================
echo payload
```
Die Datei ist nun > 32 Bytes und passiert den Check. Der Schadcode bleibt funktional.

#### 4.2 Extension vermeiden

Kombinierbar mit Extension-Bypass (2.1/2.2): Eine < 32 Byte Datei ohne verdaechtige
Endung passiert diesen Check, da `isSuspiciousExtension("")` false zurueckgibt.

---

## 5. Kombinierte Bypasses

Mehrere Techniken lassen sich kombinieren fuer maximale Evasion:

| Kombination | Umgeht | Beispiel |
|-------------|--------|----------|
| Base64 + keine Endung | Signatur + Ratio + Extension | Payload base64-encoded, als `data` gespeichert |
| String-Split + Padding + .hta | Signatur + Ratio + Extension | Obfuskierter Code in HTA-Datei |
| RTLO + Base64 | Extension + Ratio | Visuell harmloser Name, kodierter Inhalt |

---

## 6. Bekannte Design-Schwaechen

| Schwaeche | Impact | Wie ausnutzbar |
|-----------|--------|----------------|
| Extension-Check blockiert nicht | Hoch | Jede verdaechtige Datei wird nur gewarnt, nicht gestoppt |
| Signatur-Liste ist minimal | Hoch | Nur 7 Strings -- alles andere passiert unerkannt |
| Kein Archiv-Scanning | Mittel | ZIP/RAR-Container werden nicht entpackt |
| Keine Deobfuskation | Hoch | String-Splitting, Encoding, XOR etc. umgehen Signaturen |
| Keine PE/ELF-Analyse | Hoch | Executable-Header werden nicht geprueft |
| Globale Ratio statt Sections | Mittel | Padding verwaeussert die Non-Printable-Ratio |
| Kein YARA/Regex-Support | Mittel | Nur exact-match Signaturen, keine Pattern |
| Keine Verhaltensanalyse | Hoch | Kein Sandboxing, kein API-Monitoring |

---

## 6. AMSI-spezifische Bypass-Techniken

Die folgenden Techniken zielen nicht auf unseren dateibasierten Scanner, sondern auf den
**AMSI-Provider-Mechanismus** selbst. Sie demonstrieren, wie Angreifer die Windows
Anti-Malware Scan Interface umgehen.

### AMSI Architektur (Hintergrund)

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│  PowerShell  │────>│   amsi.dll   │────>│  AMSI Provider   │
│  (Host App)  │     │  (Windows)   │     │  (unsere DLL)    │
└──────────────┘     └──────────────┘     └──────────────────┘
       │                     │                      │
       │  ScriptBlock        │  AmsiScanBuffer()    │  Scan()
       │  wird ausgefuehrt   │  wird aufgerufen     │  gibt Verdict
```

Angreifer koennen an drei Stellen eingreifen:
1. **Vor AMSI** -- Verhindern, dass der Scan-Aufruf stattfindet
2. **In AMSI** -- Die Scan-Funktion selbst manipulieren
3. **Nach AMSI** -- Das Ergebnis ignorieren oder ueberschreiben

---

### 6.1 amsiInitFailed (Reflection Bypass)

**Testdatei:** `tests/06_amsi_bypass/01_amsi_init_failed.ps1`

**Angriffsvektor:** Setzt das interne Flag `amsiInitFailed` auf `True`.

**Wie es funktioniert:**
PowerShell nutzt `System.Management.Automation.AmsiUtils` mit einem privaten statischen
Feld `amsiInitFailed`. Wenn True, ueberspringt PowerShell alle AMSI-Scans.
Via .NET Reflection kann auf dieses private Feld zugegriffen werden.

**Warum es funktioniert:**
Der AMSI-Zustand wird in einer manipulierbaren .NET-Variable im User-Space gespeichert
statt in geschuetztem Kernel-Speicher. Design-Fehler: Sicherheits-kritischer Zustand
liegt im selben Adressraum wie der zu ueberwachende Code.

**Erkennung:** Unser Scanner erkennt "amsiutils" und "amsiinitfailed" als Patterns.
Die obfuskierte Version nutzt String-Splitting.

---

### 6.2 Memory Patching (AmsiScanBuffer)

**Testdatei:** `tests/06_amsi_bypass/02_amsi_memory_patch.ps1`

**Angriffsvektor:** Ueberschreibt die ersten Bytes von `AmsiScanBuffer()` mit `ret 0`.

**Wie es funktioniert:**
1. `LoadLibrary("amsi.dll")` + `GetProcAddress("AmsiScanBuffer")`
2. `VirtualProtect` hebt Speicherschutz auf
3. Erste Bytes werden mit `xor eax,eax; ret` ueberschrieben
4. Jeder folgende Scan gibt sofort AMSI_RESULT_CLEAN zurueck

**Warum es funktioniert:**
amsi.dll laeuft im User-Space. Der Prozess hat volle Kontrolle ueber seinen eigenen
Speicher. Windows schuetzt nicht gegen Selbst-Modifikation.

**Erkennung:** "VirtualAllocEx"/"WriteProcessMemory" werden als suspicious erkannt.
Moderne EDR nutzt ETW-Tracing um VirtualProtect auf amsi.dll zu erkennen.

---

### 6.3 PowerShell Downgrade (Version 2)

**Testdatei:** `tests/06_amsi_bypass/03_powershell_downgrade.ps1`

**Angriffsvektor:** Startet PowerShell v2, die AMSI nicht unterstuetzt.

**Warum es funktioniert:**
AMSI existiert erst seit PS 5.0. Die PSv2-Engine hat keinen AMSI-Hook.
`powershell.exe -Version 2` startet die alte Engine (wenn .NET 2.0/3.5 installiert).

**Erkennung:** Unser Scanner erkennt diese Datei NICHT. EDR erkennt PSv2-Starts.

---

### 6.4 Base64 + EncodedCommand

**Testdatei:** `tests/06_amsi_bypass/04_base64_encoded_command.ps1`

**Angriffsvektor:** Payload Base64-kodiert via `-EncodedCommand` ausfuehren.

**Warum es funktioniert (teilweise):**
AMSI v2 scannt den dekodierten Befehl -- allein reicht es nicht. Umgeht aber unseren
dateibasierten Scanner der Base64 nicht dekodiert. Kombination mit Memory-Patching
macht es vollstaendig wirksam.

---

### 6.5 COM Server Hijacking

**Testdatei:** `tests/06_amsi_bypass/05_com_hijacking.ps1`

**Angriffsvektor:** HKCU COM-Registrierung ueberlagert HKLM Provider.

**Warum es funktioniert:**
Windows COM durchsucht HKCU vor HKLM. Ein User kann **ohne Admin** einen HKCU-Eintrag
anlegen, der die Provider-GUID auf eine harmlose DLL umleitet.

---

### 6.6 Obfuskierte Reflection

**Testdatei:** `tests/06_amsi_bypass/06_reflection_obfuscated.ps1`

**Angriffsvektor:** amsiInitFailed mit mehrschichtiger String-Obfuskation.

**Warum es funktioniert:**
Char-Arrays, dynamische Assembly-Suche und indirekte Feld-Referenzen verhindern,
dass der Scanner die Ziel-Strings "AmsiUtils" oder "amsiInitFailed" findet.

---

### 6.7 CLM Escape + AMSI Bypass

**Testdatei:** `tests/06_amsi_bypass/07_clm_escape.ps1`

**Angriffsvektor:** Umgeht Constrained Language Mode um AMSI-Bypasses zu ermoeglichen.

**Warum es funktioniert:**
CLM beschraenkt .NET-Typ-Zugriff, aber nur innerhalb der aktuellen Session.
Externe Pfade (MSBuild, neuer Runspace) unterliegen nicht CLM.

---

### 6.8 AMSI Context Corruption

**Testdatei:** `tests/06_amsi_bypass/08_context_corruption.ps1`

**Angriffsvektor:** Setzt amsiContext auf IntPtr.Zero.

**Warum es funktioniert:**
Unguerltiger Handle -> AmsiScanBuffer schlaegt fehl -> PowerShell interpretiert
den Fehler als "scan not available" -> erlaubt Ausfuehrung.

---

### 6.9 Chunked/Fragmented Execution

**Testdatei:** `tests/06_amsi_bypass/09_chunked_execution.ps1`

**Angriffsvektor:** Payload in Fragmente aufgeteilt, die einzeln gescannt werden.

**Warum es funktioniert:**
AMSI scannt pro Buffer-Uebergabe. Einzelne Fragmente (`$p1 = "mal"`, `$p2 = "ware"`)
sind harmlos. Erst die Laufzeit-Kombination ergibt die Signatur. Fundamentale Schwaeche
aller statischen Scanner.

---

### 6.10 Fileless .NET Assembly Loading

**Testdatei:** `tests/06_amsi_bypass/10_fileless_assembly.ps1`

**Angriffsvektor:** Code direkt in Speicher laden ohne Dateisystem-Zugriff.

**Warum es funktioniert:**
`[Reflection.Assembly]::Load(byte[])` laedt Code in den RAM. Kein File-I/O ->
dateibasierte Scanner sehen den Code nie. Erst AMSI v2 (Win10 1903+) scannt
Assembly.Load-Aufrufe.

---

## 7. Neue Scanner-Checks (v2)

### 7.1 Suspicious Pattern Check

```nim
const suspiciousPatterns = [
  "invoke-expression", "iex(", "downloadstring",
  "webclient", "reflection.assembly", "frombase64string",
  "encodedcommand", "amsiutils", "amsiinitfailed",
  "virtualallocex", "writeprocessmemory", "shellcode", ...
]
```

Erkennt verdaechtige Script-Patterns. **Nur Warning** -- blockiert nicht.

### 7.2 Shannon Entropy Check

Berechnet die Informationsdichte des Dateiinhalts. Werte ueber 7.2 bits/byte
deuten auf verschluesselte/komprimierte Payloads hin. **Nur Warning.**

---

## Testausfuehrung

### Alle Tests scannen

```powershell
# Signatur-Bypasses testen:
Get-ChildItem tests\02_signature\bypass_*.ps1 | ForEach-Object {
    Write-Host "`n--- $($_.Name) ---" -ForegroundColor Cyan
    .\src\nim_antimalware_sim.exe $_.FullName
}

# AMSI-Bypass Dateien scannen:
Get-ChildItem tests\06_amsi_bypass -File | ForEach-Object {
    Write-Host "`n--- $($_.Name) ---" -ForegroundColor Cyan
    .\src\nim_antimalware_sim.exe $_.FullName
}
```

### Testdateien neu generieren

```powershell
powershell -ExecutionPolicy Bypass -File tests\scripts\create_test_files.ps1
powershell -ExecutionPolicy Bypass -File tests\scripts\create_bypass_files.ps1
```

---

## Verzeichnisstruktur der Tests

```
tests/
├── 01_clean/                  # Baseline: Saubere Dateien (BENIGN erwartet)
│   ├── clean.txt
│   ├── clean_umlaute.txt
│   └── testfile.txt
├── 02_signature/              # Signatur-Erkennung + Bypass
│   ├── malware.ps1            # DETECTED: enthalt "malware"
│   ├── malware_bypass.ps1     # BYPASS: String-Splitting
│   ├── trojan_sample.txt      # DETECTED: enthalt "trojan"
│   ├── infected.txt           # DETECTED: enthalt "MALWARE"
│   ├── bypass_xor_encoding.ps1    # BYPASS: XOR-Verschluesselung
│   ├── bypass_charcode.ps1        # BYPASS: Character-Code-Konstruktion
│   ├── bypass_reversal.ps1        # BYPASS: String-Umkehrung
│   ├── bypass_env_vars.ps1        # BYPASS: Environment Variables
│   ├── bypass_rot13.ps1           # BYPASS: ROT13 Caesar-Chiffre
│   ├── bypass_hex_encoding.ps1    # BYPASS: Hex-String-Konvertierung
│   ├── bypass_format_string.ps1   # BYPASS: Replace/Format-String
│   └── bypass_type_conversion.ps1 # BYPASS: Integer-Array + StringBuilder
├── 03_encoding/               # Non-Printable Ratio + Bypass
│   ├── utf16.txt              # DETECTED: hohe Ratio durch UTF-16 BOM
│   ├── utf16_bypass.txt       # BYPASS: Base64-Encoding
│   ├── packed.bin             # DETECTED: Zufallsbytes
│   ├── mixed.bin              # DETECTED: gemischter Inhalt
│   └── mixed_bypass.bin       # BYPASS: Ratio-Manipulation
├── 04_extension/              # Extension-Heuristik + Bypass
│   ├── extension_detected.exe # WARNING: verdaechtige Endung
│   ├── help.hta               # BYPASS: unbekannte Endung
│   ├── legacy.com             # BYPASS: unbekannte Endung
│   ├── malware_no_ext         # BYPASS: keine Endung
│   ├── document.pdf.exe       # Double Extension
│   ├── rtlo_bypass.sh         # BYPASS: RTLO Unicode
│   └── unicode_fullwidth_dot.exe  # BYPASS: Fullwidth-Punkt
├── 05_small_executable/       # Small-Executable-Check
│   ├── tiny.bat               # DETECTED: < 32 Bytes + .bat
│   └── empty.txt              # Edge-Case: 0 Bytes
├── 06_amsi_bypass/            # AMSI-spezifische Bypasses
│   ├── 01_amsi_init_failed.ps1        # amsiInitFailed Reflection
│   ├── 02_amsi_memory_patch.ps1       # AmsiScanBuffer Memory Patching
│   ├── 03_powershell_downgrade.ps1    # PSv2 Downgrade (kein AMSI)
│   ├── 04_base64_encoded_command.ps1  # Base64 + EncodedCommand
│   ├── 05_com_hijacking.ps1           # COM Provider Hijacking
│   ├── 06_reflection_obfuscated.ps1   # Obfuskierte Reflection
│   ├── 07_clm_escape.ps1             # CLM Escape + AMSI Bypass
│   ├── 08_context_corruption.ps1      # AMSI Context Nullification
│   ├── 09_chunked_execution.ps1       # Fragmentierte Ausfuehrung
│   └── 10_fileless_assembly.ps1       # In-Memory Assembly Loading
└── scripts/                   # Generierungs-Skripte
    ├── create_test_files.ps1
    └── create_bypass_files.ps1
```
