$env:DOTFILES_REPO_DIR = $PSScriptRoot

. (Join-Path $PSScriptRoot 'setup_utils\pwsh.ps1')
. (Join-Path $PSScriptRoot 'pwsh\.pwshrc.ps1')
. (Join-Path $PSScriptRoot 'git\pwsh.ps1')
. (Join-Path $PSScriptRoot 'vscode\pwsh.ps1')
