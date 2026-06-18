# XOR-Encoding Bypass
# Die Signatur "malware" wird XOR-verschluesselt gespeichert und zur Laufzeit entschluesselt
# Scanner sieht nur die verschluesselten Bytes, nicht den Klartext

$key = 0x42
$encoded = @(0x2F, 0x23, 0x2E, 0x35, 0x23, 0x30, 0x27)  # "malware" XOR 0x42
$decoded = -join ($encoded | ForEach-Object { [char]($_ -bxor $key) })
Write-Host "Executing payload: $decoded"
