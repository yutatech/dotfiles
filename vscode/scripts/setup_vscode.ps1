$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $repoRoot 'setup_utils\pwsh.ps1')

if (-not $env:APPDATA) {
    throw 'APPDATA is not set; cannot locate the VS Code user settings directory.'
}
if (-not (Get-Command code -CommandType Application -ErrorAction SilentlyContinue)) {
    throw 'Visual Studio Code is not installed or the code command is not available on PATH.'
}

$settingsPath = Join-Path $env:APPDATA 'Code\User\settings.json'
$dotfilesSettingsPath = Join-Path $repoRoot 'vscode\settings.json'
Set-DotfilesSymbolicLink -LinkPath $settingsPath -TargetPath $dotfilesSettingsPath
Write-Host "VS Code settings now use the dotfiles file: $settingsPath"
