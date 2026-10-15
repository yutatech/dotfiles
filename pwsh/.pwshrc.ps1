Import-Module PSReadLine

Set-PSReadLineOption -PredictionSource History
#Set-PSReadLineOption -PredictionViewStyle ListView

Set-PSReadLineOption -Colors @{
    Command   = 'Green'
    Parameter = 'Yellow'
    String    = 'Cyan'
    Comment   = 'DarkGreen'
}

if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSStyle.FileInfo.Directory    = "`e[34m"
    $PSStyle.FileInfo.Executable   = "`e[32m"
    $PSStyle.FileInfo.SymbolicLink = "`e[36m"
}

. (Join-Path $env:DOTFILES_REPO_DIR 'pwsh\prompt.ps1')