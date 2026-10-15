$env:DOTFILES_REPO_DIR = $PSScriptRoot

. (Join-Path $PSScriptRoot 'pwsh\.pwshrc.ps1')
. (Join-Path $PSScriptRoot 'git\pwsh.ps1')
