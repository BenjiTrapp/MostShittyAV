# Hex-Encoding Bypass
# Signatur als Hex-Werte gespeichert und zur Laufzeit konvertiert
# Scanner sieht nur "6d616c77617265" -- keine Signatur-Match

$hexPayload = "6d616c77617265"  # "malware" in hex
$bytes = [byte[]]::new($hexPayload.Length / 2)
for ($i = 0; $i -lt $hexPayload.Length; $i += 2) {
    $bytes[$i / 2] = [Convert]::ToByte($hexPayload.Substring($i, 2), 16)
}
$decoded = [System.Text.Encoding]::ASCII.GetString($bytes)
Write-Host "Payload: $decoded"
