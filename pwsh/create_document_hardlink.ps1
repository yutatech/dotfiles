$ErrorActionPreference = 'Stop'

$targetPath = [Environment]::GetFolderPath('MyDocuments')
$linkPath = Join-Path $HOME 'Documents'

if (-not $targetPath -or -not (Test-Path -LiteralPath $targetPath -PathType Container)) {
    throw 'The Windows Documents folder is not configured or does not exist.'
}

$targetPath = [System.IO.Path]::GetFullPath($targetPath).TrimEnd('\')
if ($targetPath -ieq [System.IO.Path]::GetFullPath($linkPath).TrimEnd('\')) {
    throw 'Windows Documents already points to ~/Documents; configure its OneDrive location first.'
}

$existing = Get-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue
if ($existing) {
    if ($existing.LinkType -eq 'Junction' -and
        ([string]$existing.Target).TrimEnd('\') -ieq $targetPath) {
        Write-Host "Documents junction is already configured: $linkPath -> $targetPath"
        return
    }

    throw "Cannot create the junction because the destination already exists: $linkPath"
}

# Directory hard links are not supported on Windows; use a junction instead.
New-Item -ItemType Junction -Path $linkPath -Target $targetPath | Out-Null
Write-Host "Documents junction created: $linkPath -> $targetPath"