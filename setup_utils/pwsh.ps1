function Test-DotfilesFileContentsEqual {
    param(
        [Parameter(Mandatory)][string]$FirstPath,
        [Parameter(Mandatory)][string]$SecondPath
    )

    return (Get-FileHash -LiteralPath $FirstPath -Algorithm SHA256).Hash -ceq
        (Get-FileHash -LiteralPath $SecondPath -Algorithm SHA256).Hash
}

function Test-DotfilesHardLink {
    param(
        [Parameter(Mandatory)][string]$LinkPath,
        [Parameter(Mandatory)][string]$TargetPath
    )

    if (-not (Test-Path -LiteralPath $LinkPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
        return $false
    }

    $link = Get-Item -LiteralPath $LinkPath -Force
    if ($link.LinkType -ne 'HardLink') { return $false }
    if (-not (Test-DotfilesFileContentsEqual $LinkPath $TargetPath)) { return $false }

    $fullLinkPath = [System.IO.Path]::GetFullPath($LinkPath)
    $fullTargetPath = [System.IO.Path]::GetFullPath($TargetPath)
    $linkRoot = [System.IO.Path]::GetPathRoot($fullLinkPath)
    if ($linkRoot -ine [System.IO.Path]::GetPathRoot($fullTargetPath)) { return $false }

    $fsutil = Get-Command fsutil.exe -CommandType Application -ErrorAction SilentlyContinue
    if (-not $fsutil) { return $false }

    $hardLinkPaths = @(& $fsutil.Source hardlink list $fullLinkPath 2>$null)
    if ($LASTEXITCODE -ne 0) { return $false }

    $targetRelativePath = $fullTargetPath.Substring($linkRoot.Length).TrimStart('\')
    foreach ($hardLinkPath in $hardLinkPaths) {
        $candidate = ([string]$hardLinkPath).Trim()
        if ($candidate.StartsWith('\')) {
            $candidate = Join-Path $linkRoot $candidate.TrimStart('\')
        }
        if ([System.IO.Path]::GetFullPath($candidate) -ieq $fullTargetPath) { return $true }
        if ($candidate.TrimStart('\') -ieq $targetRelativePath) { return $true }
    }

    return $false
}

function Set-DotfilesHardLink {
    param(
        [Parameter(Mandatory)][string]$LinkPath,
        [Parameter(Mandatory)][string]$TargetPath
    )

    if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
        throw "Required dotfile not found: $TargetPath"
    }

    $targetRoot = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($TargetPath))
    $linkRoot = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($LinkPath))
    if ($targetRoot -ine $linkRoot) {
        throw "Cannot create a hard link across volumes: $LinkPath -> $TargetPath"
    }

    $parentDirectory = Split-Path -Parent $LinkPath
    if (-not (Test-Path -LiteralPath $parentDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $parentDirectory -Force | Out-Null
    }

    if (Test-DotfilesHardLink -LinkPath $LinkPath -TargetPath $TargetPath) { return }

    $existing = Get-Item -LiteralPath $LinkPath -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.PSIsContainer) {
            throw "Cannot replace directory with a dotfiles hard link: $LinkPath"
        }

        $backupPath = "$LinkPath.dotfiles-backup-$(Get-Date -Format 'yyyyMMddHHmmssfff')"
        while (Test-Path -LiteralPath $backupPath) {
            $backupPath = "$LinkPath.dotfiles-backup-$(Get-Date -Format 'yyyyMMddHHmmssfff')-$([guid]::NewGuid().ToString('N'))"
        }
        Move-Item -LiteralPath $LinkPath -Destination $backupPath
        Write-Host "Existing file backed up to: $backupPath"
    }

    New-Item -ItemType HardLink -Path $LinkPath -Target $TargetPath | Out-Null
}
