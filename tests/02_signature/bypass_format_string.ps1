# Replace/Format String Bypass
# Signatur wird durch String-Formatierung/Replace zusammengebaut
# Scanner findet weder "malware" noch die Teilstrings in verdaechtiger Kombination

$template = "m_a_l_w_a_r_e"
$payload = $template -replace "_", ""
Write-Host "Loaded: $payload"

# Alternative: Format-String
$fmt = "{0}{1}{2}" -f "mal", "wa", "re"
Write-Host "Alt: $fmt"
