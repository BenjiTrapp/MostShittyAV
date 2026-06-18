# Bypass: Alternate Data Stream (NTFS ADS)
# ==========================================
# NTFS supports Alternate Data Streams - hidden data attached to files.
# The scanner reads only the main stream ($DATA) of a file.
# Content hidden in an ADS is completely invisible to the scanner.
#
# Example: file.txt has clean content in main stream
#          file.txt:hidden contains threat data in alternate stream
#
# The scanner opens "innocent.txt" and sees only "Hello World"
# The ADS "innocent.txt:hidden" is never read.
#
# EXPECTED RESULT: BENIGN (scanner does not inspect alternate data streams)

$testFile = "$env:TEMP\ads_test_$PID.txt"

# Create clean main stream
Set-Content -Path $testFile -Value "This is a completely innocent text file."

# Hide content in an Alternate Data Stream (invisible to file scanner)
$hidden = [char]109 + [char]97 + [char]108 + [char]119 + [char]97 + [char]114 + [char]101
Set-Content -Path "${testFile}:secret" -Value $hidden

# Verify: main stream is clean
Write-Host "Main stream content:"
Get-Content $testFile

# ADS content is hidden from file scanners
Write-Host "`nAlternate Data Streams:"
Get-Item $testFile -Stream * | Format-Table Stream, Length

# Read from ADS (scanner never sees this)
$recovered = Get-Content "${testFile}:secret"
Write-Host "Hidden content: $recovered"

# Cleanup
Remove-Item $testFile -Force
