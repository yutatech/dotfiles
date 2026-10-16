function Invoke-DotfilesGit {
    param([string]$Repository, [string[]]$Arguments)

    $executable = Get-Command git -CommandType Application -ErrorAction Stop | Select-Object -First 1
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new($executable.Source)
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in @('-C', $Repository, '-c', 'core.askPass=', '-c', 'credential.interactive=false') + $Arguments) {
        $startInfo.ArgumentList.Add($argument)
    }
    $startInfo.Environment['GIT_TERMINAL_PROMPT'] = '0'
    $startInfo.Environment['SSH_ASKPASS_REQUIRE'] = 'never'
    $sshCommand = $startInfo.Environment['GIT_SSH_COMMAND']
    if (-not $sshCommand) { $sshCommand = 'ssh' }
    $startInfo.Environment['GIT_SSH_COMMAND'] = "$sshCommand -oBatchMode=yes -oConnectTimeout=10"
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        $null = $process.Start()
        $process.StandardInput.Close()
        $outputTask = $process.StandardOutput.ReadToEndAsync()
        $errorTask = $process.StandardError.ReadToEndAsync()
        $finished = $process.WaitForExit(10000)
        if (-not $finished) {
            $process.Kill($true)
            $process.WaitForExit()
        }
        $outputText = $outputTask.GetAwaiter().GetResult().TrimEnd()
        $errorText = $errorTask.GetAwaiter().GetResult().TrimEnd()
        if (-not $finished) { $errorText = 'Git operation timed out after 10 seconds.' }
        [pscustomobject]@{
            ExitCode = $(if ($finished) { $process.ExitCode } else { 124 })
            Output = $outputText
            Error = $errorText
        }
    }
    finally { $process.Dispose() }
}

function Get-DotfilesUpdateState {
    param([string]$Repository)

    $main = Invoke-DotfilesGit $Repository @('rev-parse', '--verify', 'refs/heads/main')
    $upstream = Invoke-DotfilesGit $Repository @('rev-parse', '--symbolic-full-name', 'main@{upstream}')
    $remote = Invoke-DotfilesGit $Repository @('config', '--get', 'branch.main.remote')
    $merge = Invoke-DotfilesGit $Repository @('config', '--get', 'branch.main.merge')
    if ($main.ExitCode -ne 0 -or $upstream.ExitCode -ne 0 -or $remote.ExitCode -ne 0 -or $merge.ExitCode -ne 0) {
        return [pscustomobject]@{ State = 'error'; Detail = 'main or its upstream is not configured.' }
    }
    if ($remote.Output -ne '.') {
        $fetch = Invoke-DotfilesGit $Repository @('fetch', '--no-tags', '--no-write-fetch-head', '--', $remote.Output, "+$($merge.Output):$($upstream.Output)")
        if ($fetch.ExitCode -ne 0) {
            return [pscustomobject]@{ State = 'error'; Detail = $fetch.Error }
        }
    }
    $target = Invoke-DotfilesGit $Repository @('rev-parse', '--verify', 'main@{upstream}^{commit}')
    if ($target.ExitCode -ne 0) {
        return [pscustomobject]@{ State = 'error'; Detail = $target.Error }
    }
    $containsTarget = Invoke-DotfilesGit $Repository @('merge-base', '--is-ancestor', $target.Output, $main.Output)
    if ($containsTarget.ExitCode -eq 0) {
        return [pscustomobject]@{ State = 'current'; Detail = '' }
    }
    $fastForward = Invoke-DotfilesGit $Repository @('merge-base', '--is-ancestor', $main.Output, $target.Output)
    $state = if ($fastForward.ExitCode -eq 0) { 'available' } elseif ($fastForward.ExitCode -eq 1 -and $containsTarget.ExitCode -eq 1) { 'diverged' } else { 'error' }
    [pscustomobject]@{ State = $state; Detail = $fastForward.Error; Main = $main.Output; Target = $target.Output }
}

function Invoke-DotfilesUpdate {
    param([string]$Repository)

    $common = Invoke-DotfilesGit $Repository @('rev-parse', '--path-format=absolute', '--git-common-dir')
    if ($common.ExitCode -ne 0) { throw $common.Error }
    $lockPath = Join-Path $common.Output 'dotfiles-update.lock'
    $null = New-Item -ItemType Directory -Path $lockPath -ErrorAction Stop
    try {
        $state = Get-DotfilesUpdateState $Repository
        if ($state.State -eq 'current') { return $false }
        if ($state.State -ne 'available') { throw "Cannot update main: $($state.State). $($state.Detail)" }
        $branch = Invoke-DotfilesGit $Repository @('symbolic-ref', '--quiet', 'HEAD')
        $worktrees = Invoke-DotfilesGit $Repository @('worktree', 'list', '--porcelain')
        if ($worktrees.ExitCode -ne 0) { throw $worktrees.Error }
        if ($branch.Output -eq 'refs/heads/main') {
            $changes = Invoke-DotfilesGit $Repository @('status', '--porcelain', '--untracked-files=all', '--ignore-submodules=none')
            if ($changes.ExitCode -ne 0 -or $changes.Output) { throw 'Working tree is not clean; main was not updated.' }
            $result = Invoke-DotfilesGit $Repository @('merge', '--ff-only', '--no-edit', $state.Target)
        }
        else {
            if (($worktrees.Output -split '\r?\n') -contains 'branch refs/heads/main') {
                throw 'main is checked out in another worktree.'
            }
            $result = Invoke-DotfilesGit $Repository @('update-ref', 'refs/heads/main', $state.Target, $state.Main)
        }
        if ($result.ExitCode -ne 0) { throw $result.Error }
        Write-Host 'dotfiles: main updated.'
        return $true
    }
    finally { Remove-Item -LiteralPath $lockPath -Force }
}