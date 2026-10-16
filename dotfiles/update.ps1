param([switch]$NoCheck)

. (Join-Path $PSScriptRoot 'scripts\dotfiles_update.ps1')

$commandDirectory = Join-Path $env:DOTFILES_REPO_DIR 'dotfiles\cmd'
if (($env:PATH -split [IO.Path]::PathSeparator) -notcontains $commandDirectory) {
    $env:PATH = $commandDirectory + [IO.Path]::PathSeparator + $env:PATH
}

function global:dotfiles-update {
    try {
        if (-not (Invoke-DotfilesUpdate $env:DOTFILES_REPO_DIR)) {
            Write-Host 'dotfiles: main is up to date.'
            return
        }
        if ($global:DotfilesUpdateSession) {
            $global:DotfilesUpdateSession.State = 'current'
            $global:DotfilesUpdateSession.Handled = $true
        }
        . (Join-Path $env:DOTFILES_REPO_DIR 'dotfile.ps1')
        $repositoryPrefix = [IO.Path]::GetFullPath($env:DOTFILES_REPO_DIR).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
        $repositoryFunctions = @(Get-ChildItem Function: | Where-Object {
            $_.ScriptBlock.File -and [IO.Path]::GetFullPath($_.ScriptBlock.File).StartsWith($repositoryPrefix, [StringComparison]::OrdinalIgnoreCase)
        })
        foreach ($repositoryFunction in $repositoryFunctions) {
            Set-Item -Path "Function:global:$($repositoryFunction.Name)" -Value $repositoryFunction.ScriptBlock
        }
        Write-Host 'dotfiles: shell configuration reloaded.'
    }
    catch { Write-Error "dotfiles: $($_.Exception.Message)" }
}

function global:Write-DotfilesUpdateStatus {
    if (-not $global:DotfilesUpdateSession) { return }
    $previousExitCode = $global:LASTEXITCODE
    try {
        $session = $global:DotfilesUpdateSession
        if ($session.Job -and $session.Job.State -in @('Completed', 'Failed', 'Stopped')) {
            $result = @(Receive-Job $session.Job -ErrorAction SilentlyContinue)
            Remove-Job $session.Job -Force
            $session.Job = $null
            if ($result.Count -gt 0 -and $result[-1].State) {
                $session.State = $result[-1].State
                $session.Detail = $result[-1].Detail
                $session.Target = $result[-1].Target
            }
            else { $session.State = 'error'; $session.Detail = 'Background check failed.' }
        }
        if ($session.State -eq 'available') {
            $alreadyUpdated = Invoke-DotfilesGit $env:DOTFILES_REPO_DIR @('merge-base', '--is-ancestor', $session.Target, 'refs/heads/main')
            if ($alreadyUpdated.ExitCode -eq 0) { $session.State = 'current'; return }
            Write-Host '[main update available]' -ForegroundColor Yellow
            if (-not $session.Handled) {
                $session.Handled = $true
                $answer = Read-Host 'Update dotfiles main now? [y/N]'
                if ($answer -cmatch '^[yY]$') { dotfiles-update }
            }
        }
        elseif ($session.State -in @('error', 'diverged') -and -not $session.Handled) {
            $session.Handled = $true
            $detail = if ($session.State -eq 'diverged') { 'main has diverged; automatic update is unavailable.' } else { $session.Detail }
            $detail = ($detail -replace '[\r\n]+', ' ')
            if ($detail.Length -gt 240) { $detail = $detail.Substring(0, 240) }
            Write-Host "dotfiles: $detail" -ForegroundColor Yellow
        }
    }
    finally { $global:LASTEXITCODE = $previousExitCode }
}

$commandLine = [Environment]::GetCommandLineArgs()
$nonInteractive = $commandLine | Where-Object { $_ -match '^-(NonI(nteractive)?|File|f|Command(WithArgs)?|c|EncodedCommand|e|ec)$' }
$noExit = $commandLine | Where-Object { $_ -eq '-NoExit' }
if (-not $NoCheck -and -not $global:DotfilesUpdateSession -and
    (-not $nonInteractive -or $noExit) -and -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected) {
    $global:DotfilesUpdateSession = [pscustomobject]@{
        State = 'checking'; Handled = $false; Detail = ''; Target = ''; Job = $null
    }
    $global:DotfilesUpdateSession.Job = Start-Job -ScriptBlock {
        param($scriptPath, $repository)
        try {
            . $scriptPath
            Get-DotfilesUpdateState $repository
        }
        catch { [pscustomobject]@{ State = 'error'; Detail = $_.Exception.Message } }
    } -ArgumentList (Join-Path $env:DOTFILES_REPO_DIR 'dotfiles\scripts\dotfiles_update.ps1'), $env:DOTFILES_REPO_DIR
}