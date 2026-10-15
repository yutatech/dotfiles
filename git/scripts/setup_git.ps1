$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$gitConfig = Join-Path $repoRoot 'git\.gitconfig'
$globalIgnore = Join-Path $repoRoot 'git\.gitignore_global'
$userGitConfig = Join-Path $HOME '.gitconfig'
$userGlobalIgnore = Join-Path $HOME '.gitignore_global'

. (Join-Path $repoRoot 'setup_utils\pwsh.ps1')

foreach ($path in @($gitConfig, $globalIgnore)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required dotfile not found: $path"
    }
}

if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) {
    throw 'Git is not installed or is not available on PATH.'
}

Set-DotfilesHardLink -LinkPath $userGitConfig -TargetPath $gitConfig
Set-DotfilesHardLink -LinkPath $userGlobalIgnore -TargetPath $globalIgnore
Write-Host 'Git configuration now points to the dotfiles repository.'
