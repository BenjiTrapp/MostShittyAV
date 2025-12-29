$code = @"
Write-Host "This is a test"
# AMSI scans this content
"@

Invoke-Expression $code