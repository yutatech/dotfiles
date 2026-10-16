if (-not $env:DOTFILES_REPO_DIR) {
    $env:DOTFILES_REPO_DIR = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
. (Join-Path $env:DOTFILES_REPO_DIR 'dotfiles\update.ps1') -NoCheck
dotfiles-update