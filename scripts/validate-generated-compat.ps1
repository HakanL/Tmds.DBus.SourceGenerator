param(
    [string]$GeneratedRoot = "DebugSourceGenerator/obj/Release/net8.0/generated"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $GeneratedRoot)) {
    throw "Generated source directory not found: $GeneratedRoot"
}

$generatedFiles = Get-ChildItem -Path $GeneratedRoot -Recurse -Filter *.g.cs
if ($generatedFiles.Count -eq 0) {
    throw "No generated source files found under: $GeneratedRoot"
}

$legacyPatterns = @(
    '\bTmds\.DBus\.Connection\b',
    '\bIMethodHandler\b'
)

$violations = @()
foreach ($pattern in $legacyPatterns) {
    $matches = Select-String -Path $generatedFiles.FullName -Pattern $pattern
    foreach ($match in $matches) {
        $violations += "{0}:{1}: {2}" -f $match.Path, $match.LineNumber, $match.Line.Trim()
    }
}

if ($violations.Count -gt 0) {
    Write-Error "Detected legacy Tmds.DBus symbols in generated output:"
    $violations | Select-Object -First 20 | ForEach-Object { Write-Error $_ }
    throw "Generated output contains symbols incompatible with Tmds.DBus.Protocol 0.94.0"
}

$modernMatches = Select-String -Path $generatedFiles.FullName -Pattern '\bDBusConnection\b'
if ($modernMatches.Count -eq 0) {
    throw "Expected DBusConnection symbol not found in generated output."
}

Write-Host "Generated compatibility validation passed. Files scanned: $($generatedFiles.Count)."