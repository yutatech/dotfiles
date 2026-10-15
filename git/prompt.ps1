function Test-InGitRepo {
    param([string]$Path)

    $directory = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    while ($directory) {
        if (Test-Path -LiteralPath (Join-Path $directory.FullName '.git')) {
            return $true
        }
        $directory = $directory.Parent
    }
    return $false
}

function Get-GitPromptStatus {
    if (-not $global:DotfilesGitExecutable) { return $null }
    if (-not (Test-InGitRepo (Get-Location).Path)) { return $null }

    $gitExecutable = $global:DotfilesGitExecutable.Source
    $lines = & $gitExecutable --no-optional-locks status --porcelain=v2 --branch --show-stash 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $lines) { return $null }

    $branch = $null
    $ahead = 0
    $behind = 0
    $hasUpstream = $false
    $hasStash = $false
    $staged = $false
    $unstaged = $false
    $untracked = $false

    foreach ($line in $lines) {
        switch -regex ($line) {
            '^# branch\.head (.+)$'         { $branch = $Matches[1]; continue }
            '^# branch\.upstream '          { $hasUpstream = $true; continue }
            '^# branch\.ab \+(\d+) -(\d+)$' { $ahead = [int]$Matches[1]; $behind = [int]$Matches[2]; continue }
            '^# stash (\d+)$'               { if ([int]$Matches[1] -gt 0) { $hasStash = $true }; continue }
            '^[12] (..) '                    {
                if ($Matches[1][0] -ne '.') { $staged = $true }
                if ($Matches[1][1] -ne '.') { $unstaged = $true }
                continue
            }
            '^u '                            { $staged = $true; $unstaged = $true; continue }
            '^\? '                           { $untracked = $true; continue }
        }
    }

    if ($branch -eq '(detached)') {
        $shortHash = & $gitExecutable rev-parse --short HEAD 2>$null
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
