. (Join-Path $env:DOTFILES_REPO_DIR 'git\prompt.ps1')

$global:DotfilesGitExecutable = Get-Command git -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1

function Test-DotfilesGitConfiguration {
    if (-not $global:DotfilesGitExecutable) { return $false }

    $repoRoot = $env:DOTFILES_REPO_DIR
    $gitConfig = Join-Path $repoRoot 'git\.gitconfig'
    $globalIgnore = Join-Path $repoRoot 'git\.gitignore_global'
    $userGitConfig = Join-Path $HOME '.gitconfig'
    $userGlobalIgnore = Join-Path $HOME '.gitignore_global'

    foreach ($path in @($gitConfig, $globalIgnore, $userGitConfig, $userGlobalIgnore)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
    }

    if (-not (Test-DotfilesSymbolicLink $userGitConfig $gitConfig)) { return $false }
    if (-not (Test-DotfilesSymbolicLink $userGlobalIgnore $globalIgnore)) { return $false }

    $gitExecutable = $global:DotfilesGitExecutable.Source
    $configuredIgnore = @(& $gitExecutable config --global --path core.excludesfile 2>$null)
    if ($LASTEXITCODE -ne 0 -or $configuredIgnore.Count -eq 0) { return $false }

    $configuredIgnorePath = [System.IO.Path]::GetFullPath([string]$configuredIgnore[-1])
    if ($configuredIgnorePath -ine [System.IO.Path]::GetFullPath($userGlobalIgnore)) { return $false }

    $configOrigin = @(& $gitExecutable config --global --show-origin --get core.excludesfile 2>$null)
    if ($LASTEXITCODE -ne 0 -or $configOrigin.Count -eq 0) { return $false }
    $originLine = [string]$configOrigin[-1]
    $separator = $originLine.IndexOf("`t")
    if ($separator -lt 6 -or -not $originLine.StartsWith('file:')) { return $false }

    $originPath = [System.IO.Path]::GetFullPath($originLine.Substring(5, $separator - 5))
    return $originPath -ieq [System.IO.Path]::GetFullPath($userGitConfig)
}

if ($global:DotfilesGitExecutable) {
    function global:git {
        if (-not (Test-DotfilesGitConfiguration)) {
            Write-Host 'Git is not configured to use the dotfiles repository.'
            $answer = Read-Host 'Run the Git setup script now? [y/N]'
            if ($answer -notmatch '^(y|yes)$') { return }

            $setupScript = Join-Path $env:DOTFILES_REPO_DIR 'git\scripts\setup_git.ps1'
            & $setupScript
            if (-not (Test-DotfilesGitConfiguration)) {
                Write-Error 'Git setup did not configure the dotfiles paths; git remains unavailable through this prompt.'
                return
            }
        }

        if ($args.Count -gt 0 -and $args[0] -in @('clear', 'fixup', 'graph')) {
            $commandPath = Join-Path $env:DOTFILES_REPO_DIR "git\cmd\git-$($args[0]).ps1"
            $commandArguments = @($args | Select-Object -Skip 1)
            & $commandPath @commandArguments
            return
        }

        & $global:DotfilesGitExecutable.Source @args
    }

    . (Join-Path $env:DOTFILES_REPO_DIR 'git\comp\git.ps1')
}
