# AMSI Bypass: Base64 Encoded Command
# ======================================
# ACHTUNG: Dies ist eine BILDUNGSDATEI. Nicht auf Produktivsystemen ausfuehren!
#
# TECHNIK: Payload wird Base64-kodiert und via -EncodedCommand ausgefuehrt.
#
# WARUM ES FUNKTIONIERT (teilweise):
# AMSI scannt den DEKODIERTEN Befehl -- dieser Bypass allein reicht also
# gegen moderne AMSI-Implementierungen NICHT. Er demonstriert aber:
# 1. Wie File-basierte Scanner umgangen werden (unser Scanner sieht nur Base64)
# 2. Dass die KOMBINATION mit amsiInitFailed oder Memory-Patching wirkt
# 3. Wie Angreifer mehrstufige Payloads aufbauen
#
# ERKENNUNG DURCH UNSEREN SCANNER:
# - "FromBase64String" wird als suspicious pattern erkannt
# - Aber der eigentliche Payload ist im Base64 versteckt
# - Unser Scanner dekodiert NICHT -- der Inhalt bleibt unsichtbar

# Payload: "Write-Host 'malware executed successfully'"
$encodedPayload = "VwByAGkAdABlAC0ASABvAHMAdAAgACcAbQBhAGwAdwBhAHIAZQAgAGUAeABlAGMAdQB0AGUAZAAgAHMAdQBjAGMAZQBzAHMAZgB1AGwAbAB5ACcA"

# Variante 1: Direkte Ausfuehrung (AMSI scannt den dekodierten String!)
# powershell.exe -EncodedCommand $encodedPayload

# Variante 2: Manuelle Dekodierung (umgeht file-basierten Scanner)
$decoded = [System.Text.Encoding]::Unicode.GetString(
    [System.Convert]::FromBase64String($encodedPayload)
)
Write-Host "Decoded payload (not executing): $decoded"

# Variante 3: Verschachteltes Encoding (mehrere Layer)
$layer1 = [Convert]::ToBase64String(
    [Text.Encoding]::Unicode.GetBytes(
        "Invoke-Expression 'Write-Host payload_active'"
    )
)
Write-Host "Double-encoded (Layer 1): $layer1"
