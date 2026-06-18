# ROT13 / Caesar Cipher Bypass
# Signatur wird mit Caesar-Verschiebung (+13) gespeichert
# Scanner kann den verschobenen Text nicht als Signatur erkennen

function Invoke-ROT13([string]$text) {
    $result = ""
    foreach ($c in $text.ToCharArray()) {
        if ($c -ge 'a' -and $c -le 'z') {
            $result += [char](((([int]$c - 97 + 13) % 26) + 97))
        } elseif ($c -ge 'A' -and $c -le 'Z') {
            $result += [char](((([int]$c - 65 + 13) % 26) + 65))
        } else {
            $result += $c
        }
    }
    return $result
}

$encoded = "znyJner"  # "malWare" in ROT13
$decoded = Invoke-ROT13 $encoded
Write-Host "Decoded: $decoded"
