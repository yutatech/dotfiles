$profileDirectory = Split-Path -Parent $PROFILE
if (-not (Test-Path -LiteralPath $profileDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $PROFILE -PathType Leaf)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

$dotfilePath = Join-Path $PSScriptRoot 'dotfile.ps1'
$escapedDotfilePath = $dotfilePath -replace "'", "''"
$sourceLine = ". '$escapedDotfilePath'"

if (-not ((Get-Content -LiteralPath $PROFILE) -contains $sourceLine)) {
    Add-Content -LiteralPath $PROFILE -Value $sourceLine
}