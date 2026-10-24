$ErrorActionPreference = 'Stop'

. (Join-Path (Split-Path -Parent $PSScriptRoot) 'setup_utils\pwsh.ps1')

$targetPath = [Environment]::GetFolderPath('MyDocuments')
$linkPath = Join-Path $HOME 'Documents'

if (-not $targetPath -or -not (Test-Path -LiteralPath $targetPath -PathType Container)) {
    throw 'The Windows Documents folder is not configured or does not exist.'
}

$targetPath = [System.IO.Path]::GetFullPath($targetPath).TrimEnd('\')
if ($targetPath -ieq [System.IO.Path]::GetFullPath($linkPath).TrimEnd('\')) {
    throw 'Windows Documents already points to ~/Documents; configure its OneDrive location first.'
}

Set-DotfilesSymbolicLink -LinkPath $linkPath -TargetPath $targetPath