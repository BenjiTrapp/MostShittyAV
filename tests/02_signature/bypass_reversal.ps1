# String Reversal Bypass
# Die Signatur wird rueckwaerts gespeichert und zur Laufzeit umgedreht
# Scanner prueft nur vorwaerts-Matching

$reversed = "erawlam"
$payload = -join ($reversed[-1..-($reversed.Length)])
Write-Host "Loaded: $payload"
