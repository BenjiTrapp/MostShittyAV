# Environment Variable Bypass
# Signatur-Teile werden in Umgebungsvariablen gespeichert
# Scanner sieht nur die Variablennamen, nicht den aufgeloesten Wert

$env:__P1 = "mal"
$env:__P2 = "ware"
$result = $env:__P1 + $env:__P2
Write-Host "Payload: $result"
Remove-Item Env:__P1, Env:__P2
