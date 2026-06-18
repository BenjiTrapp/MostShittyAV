# Type Conversion Bypass
# Signatur wird als Integer-Array kodiert und durch Typ-Konvertierung wiederhergestellt
# Scanner sieht nur Zahlen, keine Strings

$intArray = @(109, 97, 108, 119, 97, 114, 101)
$sb = New-Object System.Text.StringBuilder
$intArray | ForEach-Object { [void]$sb.Append([char]$_) }
$payload = $sb.ToString()
Write-Host "Result: $payload"
