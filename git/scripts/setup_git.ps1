$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$gitConfig = Join-Path $repoRoot 'git\.gitconfig'
$globalIgnore = Join-Path $repoRoot 'git\.gitignore_global'
$userGitConfig = Join-Path $HOME '.gitconfig'
$userGlobalIgnore = Join-Path $HOME '.gitignore_global'

foreach ($path in @($gitConfig, $globalIgnore)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required dotfile not found: $path"
    }
}

if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) {
    throw 'Git is not installed or is not available on PATH.'
}

function Test-FileContentsEqual {
    param(
        [Parameter(Mandatory)][string]$FirstPath,
        [Parameter(Mandatory)][string]$SecondPath
    )

    return (Get-FileHash -LiteralPath $FirstPath -Algorithm SHA256).Hash -ceq
        (Get-FileHash -LiteralPath $SecondPath -Algorithm SHA256).Hash
}

function Set-DotfilesHardLink {
    param(
        [Parameter(Mandatory)][string]$LinkPath,
        [Parameter(Mandatory)][string]$TargetPath
    )

    $existing = Get-Item -LiteralPath $LinkPath -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.PSIsContainer) {
            throw "Cannot replace directory with a dotfiles link: $LinkPath"
        }

        if ($existing.LinkType -and $existing.Target) {
            $existingTarget = [string]$existing.Target
            if (-not [System.IO.Path]::IsPathRooted($existingTarget)) {
                $existingTarget = Join-Path $existing.DirectoryName $existingTarget
            }
            if ([System.IO.Path]::GetFullPath($existingTarget) -ieq [System.IO.Path]::GetFullPath($TargetPath)) {
                return
            }
        }
        elseif (Test-FileContentsEqual -FirstPath $LinkPath -SecondPath $TargetPath) {
            return
        }

        $backupPath = "$LinkPath.dotfiles-backup-$(Get-Date -Format 'yyyyMMddHHmmssfff')"
        Move-Item -LiteralPath $LinkPath -Destination $backupPath
        Write-Host "Existing file backed up to: $backupPath"
    }

    New-Item -ItemType HardLink -Path $LinkPath -Target $TargetPath | Out-Null
}

Set-DotfilesHardLink -LinkPath $userGitConfig -TargetPath $gitConfig
Set-DotfilesHardLink -LinkPath $userGlobalIgnore -TargetPath $globalIgnore
Write-Host 'Git configuration now points to the dotfiles repository.'
