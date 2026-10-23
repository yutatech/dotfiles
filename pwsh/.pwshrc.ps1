Import-Module PSReadLine

Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete        # タブ補完をメニュー形式に変更
Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit # Ctrl+dで文字削除または終了
Set-PSReadLineOption -PredictionSource History                  # 入力予測をゴースト表示
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

Get-ChildItem -Path (Join-Path $PSScriptRoot 'bin') -Filter '*.ps1' -File -Recurse |
    Sort-Object -Property FullName |
    ForEach-Object { . $_.FullName }
