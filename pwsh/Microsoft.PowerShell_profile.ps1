Import-Module PSReadLine

Set-PSReadLineOption -PredictionSource History
#Set-PSReadLineOption -PredictionViewStyle ListView

Set-PSReadLineOption -Colors @{
    Command   = 'Green'
    Parameter = 'Yellow'
    String    = 'Cyan'
    Comment   = 'DarkGreen'
}

# ===== gitコマンドの存在確認はキャッシュ(毎回PATH探索しない) =====
$script:GitAvailable = Get-Command git -ErrorAction SilentlyContinue

# ===== .gitの有無を.NETファイル操作で判定(プロセス起動なし) =====
function Test-InGitRepo {
    param([string]$Path)
    $dir = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    while ($dir) {
        if (Test-Path -LiteralPath (Join-Path $dir.FullName '.git')) { return $true }
        $dir = $dir.Parent
    }
    return $false
}

# ===== Git状態を1回のgit呼び出しだけで取得 =====
function Get-GitPromptStatus {
    if (-not $script:GitAvailable) { return $null }
    if (-not (Test-InGitRepo (Get-Location).Path)) { return $null }

    $lines = git --no-optional-locks status --porcelain=v2 --branch --show-stash 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $lines) { return $null }

    $branch = $null; $ahead = 0; $behind = 0
    $hasUpstream = $false; $hasStash = $false
    $staged = $false; $unstaged = $false; $untracked = $false

    foreach ($line in $lines) {
        switch -regex ($line) {
            '^# branch\.head (.+)$'        { $branch = $Matches[1]; continue }
            '^# branch\.upstream '         { $hasUpstream = $true; continue }
            '^# branch\.ab \+(\d+) -(\d+)$'{ $ahead = [int]$Matches[1]; $behind = [int]$Matches[2]; continue }
            '^# stash (\d+)$'              { if ([int]$Matches[1] -gt 0) { $hasStash = $true }; continue }
            '^[12] (..) '                  { if ($Matches[1][0] -ne '.') { $staged = $true }
                                              if ($Matches[1][1] -ne '.') { $unstaged = $true }; continue }
            '^u '                          { $staged = $true; $unstaged = $true; continue }
            '^\? '                        { $untracked = $true; continue }
        }
    }

    if ($branch -eq '(detached)') {
        $shortHash = git rev-parse --short HEAD 2>$null
        $branch = if ($shortHash) { "($shortHash)" } else { '(unknown)' }
    }

    $flags = ''
    if ($unstaged)  { $flags += '*' }
    if ($staged)    { $flags += '+' }
    if ($untracked) { $flags += '%' }
    if ($hasStash)  { $flags += '$' }

    if ($hasUpstream) {
        if     ($ahead -gt 0 -and $behind -gt 0) { $flags += '<>' }
        elseif ($ahead -gt 0)  { $flags += '>' }
        elseif ($behind -gt 0) { $flags += '<' }
        else                   { $flags += '=' }
    }

    return "($branch$flags)"
}

# ===== プロンプト本体 =====
function prompt {
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $symbol = if ($isAdmin) { '#' } else { '$' }

    $userName     = $env:USERNAME
    $computerName = $env:COMPUTERNAME
    $currentPath  = (Get-Location).Path
    $homePath     = [System.Environment]::GetFolderPath('UserProfile')
    if ($currentPath.StartsWith($homePath)) {
        $currentPath = '~' + $currentPath.Substring($homePath.Length)
    }

    $gitStatus = Get-GitPromptStatus
    if ($gitStatus) {
        $columns = $Host.UI.RawUI.WindowSize.Width
        $col = $columns - $gitStatus.Length + 1
        if ($col -lt 1) { $col = 1 }

        Write-Host "`e[${col}G" -NoNewline
        Write-Host "`e[1;32m$gitStatus`e[0m" -NoNewline
        Write-Host "`e[1G" -NoNewline
    }

    Write-Host "$userName@$computerName" -ForegroundColor Green -NoNewline
    Write-Host ':' -NoNewline
    Write-Host $currentPath -ForegroundColor Blue -NoNewline

    return "$symbol "
}

# ===== ls 風の色付け(PowerShell 7 以降) =====
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSStyle.FileInfo.Directory    = "`e[34m"
    $PSStyle.FileInfo.Executable   = "`e[32m"
    $PSStyle.FileInfo.SymbolicLink = "`e[36m"
}

$env:Path += "C:\Users\0000412398\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Python 3.13"
