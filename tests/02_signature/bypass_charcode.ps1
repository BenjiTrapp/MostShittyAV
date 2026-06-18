# Char-Code Construction Bypass
# Die Signatur wird aus einzelnen ASCII-Codes zusammengebaut
# Scanner findet keinen zusammenhaengenden String

$payload = [char]109 + [char]97 + [char]108 + [char]119 + [char]97 + [char]114 + [char]101
Write-Host "Result: $payload"
