function Test-DotfilesSymbolicLink {
    param(
        [Parameter(Mandatory)][string]$LinkPath,
        [Parameter(Mandatory)][string]$TargetPath
    )

    if (-not (Test-Path -LiteralPath $TargetPath)) { return $false }
    try { $link = Get-Item -LiteralPath $LinkPath -Force -ErrorAction Stop }
    catch [System.Management.Automation.ItemNotFoundException] { return $false }
    if ($link.LinkType -ne 'SymbolicLink' -or -not $link.Target) { return $false }

    $destination = [string]$link.Target
    if (-not [IO.Path]::IsPathRooted($destination)) {
        $destination = Join-Path (Split-Path -Parent ([IO.Path]::GetFullPath($LinkPath))) $destination
    }
    return [IO.Path]::GetFullPath($destination).TrimEnd('\', '/') -ieq
        [IO.Path]::GetFullPath($TargetPath).TrimEnd('\', '/')
}

function Set-DotfilesSymbolicLink {
    param(
        [Parameter(Mandatory)][string]$LinkPath,
        [Parameter(Mandatory)][string]$TargetPath
    )

    $LinkPath = [IO.Path]::GetFullPath($LinkPath)
    $TargetPath = [IO.Path]::GetFullPath($TargetPath)
    if ($LinkPath.TrimEnd('\', '/') -ieq $TargetPath.TrimEnd('\', '/')) {
        throw "A symbolic link cannot target itself: $LinkPath"
    }
    if (-not (Test-Path -LiteralPath $TargetPath)) {
        throw "Required dotfile not found: $TargetPath"
    }
    if (Test-DotfilesSymbolicLink -LinkPath $LinkPath -TargetPath $TargetPath) { return }

    $parentDirectory = Split-Path -Parent $LinkPath
    if (-not (Test-Path -LiteralPath $parentDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $parentDirectory -Force -ErrorAction Stop | Out-Null
    }

    $existing = $null
    try { $existing = Get-Item -LiteralPath $LinkPath -Force -ErrorAction Stop }
    catch [System.Management.Automation.ItemNotFoundException] { }
    $backupPath = $null
    $replaceJunction = $false
    if ($existing) {
        if ($existing.PSIsContainer) {
            $replaceJunction = $existing.LinkType -eq 'Junction' -and
                ([IO.Path]::GetFullPath([string]$existing.Target).TrimEnd('\', '/') -ieq $TargetPath.TrimEnd('\', '/'))
            if (-not $replaceJunction) {
                throw "Cannot replace an existing directory or directory link: $LinkPath"
            }
        }

        $backupPath = "$LinkPath.dotfiles-backup-$([guid]::NewGuid().ToString('N'))"
        Move-Item -LiteralPath $LinkPath -Destination $backupPath -ErrorAction Stop
    }

    try {
        $escapedLink = $LinkPath.Replace("'", "''")
        $escapedTarget = $TargetPath.Replace("'", "''")
        $command = @"
`$ErrorActionPreference = 'Stop'
try {
    New-Item -ItemType SymbolicLink -Path '$escapedLink' -Target '$escapedTarget' | Out-Null
    exit 0
}
catch {
    Write-Error -ErrorRecord `$_ -ErrorAction Continue
    exit 1
}
"@
        # EncodedCommand preserves spaces, quotes and Unicode through Windows argument parsing.
        $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $process = Start-Process -FilePath (Join-Path $PSHOME 'pwsh.exe') -Verb RunAs -Wait -PassThru `
            -ArgumentList @('-NoLogo', '-NoProfile', '-NonInteractive', '-EncodedCommand', $encodedCommand) -ErrorAction Stop
        try {
            if ($process.ExitCode -ne 0) {
                throw "Elevated symbolic link creation failed with exit code $($process.ExitCode): $LinkPath"
            }
        }
        finally { $process.Dispose() }
        if (-not (Test-DotfilesSymbolicLink -LinkPath $LinkPath -TargetPath $TargetPath)) {
            throw "The expected symbolic link was not created: $LinkPath -> $TargetPath"
        }
    }
    catch {
        if ($backupPath) {
            $created = $null
            try { $created = Get-Item -LiteralPath $LinkPath -Force -ErrorAction Stop }
            catch [System.Management.Automation.ItemNotFoundException] { }
            if (-not $created) {
                Move-Item -LiteralPath $backupPath -Destination $LinkPath -ErrorAction Stop
            }
            else {
                throw "Symbolic link setup failed; the original remains at ${backupPath}. $($_.Exception.Message)"
            }
        }
        throw
    }
    if ($replaceJunction) {
        # Delete only the old junction, never its target directory.
        [IO.Directory]::Delete($backupPath)
    }
    elseif ($backupPath) { Write-Host "Existing file backed up to: $backupPath" }
    Write-Host "Symbolic link configured: $LinkPath -> $TargetPath"
}
