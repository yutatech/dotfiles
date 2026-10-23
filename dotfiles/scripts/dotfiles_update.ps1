param([string]$CheckRepository)

function Invoke-DotfilesGit {
    param([string]$Repository, [string[]]$Arguments, [switch]$ShowOutput)

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
        $outputText = ''
        $errorText = ''
        if ($ShowOutput) {
            $timer = [Diagnostics.Stopwatch]::StartNew()
            $streams = @(
                @{ Reader = $process.StandardOutput; Task = $process.StandardOutput.ReadLineAsync(); Text = [Text.StringBuilder]::new() }
                @{ Reader = $process.StandardError; Task = $process.StandardError.ReadLineAsync(); Text = [Text.StringBuilder]::new() }
            )
            $finished = $true
            while ($pending = @($streams | Where-Object { $null -ne $_.Task })) {
                $remaining = [int][Math]::Max(0, 10000 - $timer.ElapsedMilliseconds)
                $tasks = [Threading.Tasks.Task[]]@($pending | ForEach-Object { $_.Task })
                if ($remaining -eq 0 -or [Threading.Tasks.Task]::WaitAny($tasks, $remaining) -eq -1) {
                    $finished = $false
                    break
                }
                foreach ($stream in $pending) {
                    if (-not $stream.Task.IsCompleted) { continue }
                    $line = $stream.Task.GetAwaiter().GetResult()
                    if ($null -eq $line) { $stream.Task = $null; continue }
                    $null = $stream.Text.AppendLine($line)
                    Write-Host $line
                    $stream.Task = $stream.Reader.ReadLineAsync()
                }
            }
            if ($finished) {
                $finished = $process.WaitForExit([int][Math]::Max(0, 10000 - $timer.ElapsedMilliseconds))
            }
            $outputText = $streams[0].Text.ToString().TrimEnd()
            $errorText = $streams[1].Text.ToString().TrimEnd()
        }
        else {
            $outputTask = $process.StandardOutput.ReadToEndAsync()
            $errorTask = $process.StandardError.ReadToEndAsync()
            $finished = $process.WaitForExit(10000)
        }
        if (-not $finished) {
            $process.Kill($true)
            $process.WaitForExit()
        }
        if (-not $ShowOutput) {
            $outputText = $outputTask.GetAwaiter().GetResult().TrimEnd()
            $errorText = $errorTask.GetAwaiter().GetResult().TrimEnd()
        }
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
    param([string]$Repository, [switch]$ShowOutput)

    $main = Invoke-DotfilesGit $Repository @('rev-parse', '--verify', 'refs/heads/main')
    $upstream = Invoke-DotfilesGit $Repository @('rev-parse', '--symbolic-full-name', 'main@{upstream}')
    $remote = Invoke-DotfilesGit $Repository @('config', '--get', 'branch.main.remote')
    $merge = Invoke-DotfilesGit $Repository @('config', '--get', 'branch.main.merge')
    if ($main.ExitCode -ne 0 -or $upstream.ExitCode -ne 0 -or $remote.ExitCode -ne 0 -or $merge.ExitCode -ne 0) {
        return [pscustomobject]@{ State = 'error'; Detail = 'main or its upstream is not configured.' }
    }
    if ($remote.Output -ne '.') {
        $fetchArguments = @('fetch', '--no-tags', '--no-write-fetch-head')
        if ($ShowOutput) { $fetchArguments += '--verbose' }
        $fetchArguments += @('--', $remote.Output, "+$($merge.Output):$($upstream.Output)")
        $fetch = Invoke-DotfilesGit $Repository $fetchArguments -ShowOutput:$ShowOutput
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

function Test-DotfilesAutostash {
    param([string]$Repository, [string]$Main, [string]$Target)

    $added = Invoke-DotfilesGit $Repository @('diff', '--no-renames', '--name-only', '-z', '--diff-filter=A', $Main, $Target)
    if ($added.ExitCode -ne 0) { throw $added.Error }
    foreach ($path in ($added.Output -split "`0" | Where-Object { $_ })) {
        $fullPath = Join-Path $Repository $path
        if (Test-Path -LiteralPath $fullPath) {
            $untracked = Invoke-DotfilesGit $Repository @('--literal-pathspecs', 'ls-files', '--others', '-z', '--', $path)
            if ($untracked.ExitCode -ne 0) { throw $untracked.Error }
            if ($untracked.Output) { throw "Untracked or ignored path would be overwritten: $path; main was not updated." }
        }
        $parentPath = $path
        while ($parentPath.Contains('/')) {
            $parentPath = $parentPath.Substring(0, $parentPath.LastIndexOf('/'))
            $parent = Join-Path $Repository $parentPath
            if ((Test-Path -LiteralPath $parent) -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
                $untracked = Invoke-DotfilesGit $Repository @('--literal-pathspecs', 'ls-files', '--others', '-z', '--', $parentPath)
                if ($untracked.ExitCode -ne 0) { throw $untracked.Error }
                if ($untracked.Output) { throw "Untracked or ignored path blocks: $path; main was not updated." }
            }
        }
    }

    # stash create snapshots tracked changes without changing the index, worktree or stash list.
    $snapshot = Invoke-DotfilesGit $Repository @('stash', 'create')
    if ($snapshot.ExitCode -ne 0) { throw $snapshot.Error }
    if (-not $snapshot.Output) { return }
    $preview = Join-Path ([IO.Path]::GetTempPath()) "dotfiles-autostash-$([guid]::NewGuid().ToString('N'))"
    $created = $false
    try {
        $result = Invoke-DotfilesGit $Repository @('worktree', 'add', '--detach', $preview, $Target)
        if ($result.ExitCode -ne 0) { throw $result.Error }
        $created = $true
        $result = Invoke-DotfilesGit $preview @('stash', 'apply', $snapshot.Output)
        if ($result.ExitCode -ne 0) {
            throw "Autostash would conflict; main, working tree, index and stash were not changed. $($result.Output) $($result.Error)"
        }
    }
    finally {
        if ($created) {
            $cleanup = Invoke-DotfilesGit $Repository @('worktree', 'remove', '--force', $preview)
            if ($cleanup.ExitCode -ne 0) { throw "Cannot remove preview worktree ${preview}: $($cleanup.Error)" }
        }
    }
}

function Invoke-DotfilesUpdate {
    param([string]$Repository)

    $common = Invoke-DotfilesGit $Repository @('rev-parse', '--path-format=absolute', '--git-common-dir')
    if ($common.ExitCode -ne 0) { throw $common.Error }
    $lockPath = Join-Path $common.Output 'dotfiles-update.lock'
    $null = New-Item -ItemType Directory -Path $lockPath -ErrorAction Stop
    try {
        $state = Get-DotfilesUpdateState $Repository -ShowOutput
        if ($state.State -eq 'current') { return $false }
        if ($state.State -ne 'available') { throw "Cannot update main: $($state.State). $($state.Detail)" }
        $branch = Invoke-DotfilesGit $Repository @('symbolic-ref', '--quiet', 'HEAD')
        $worktrees = Invoke-DotfilesGit $Repository @('worktree', 'list', '--porcelain')
        if ($worktrees.ExitCode -ne 0) { throw $worktrees.Error }
        if ($branch.Output -eq 'refs/heads/main') {
            Test-DotfilesAutostash $Repository $state.Main $state.Target
            $result = Invoke-DotfilesGit $Repository @('merge', '--ff-only', '--autostash', '--no-overwrite-ignore', '--no-edit', $state.Target) -ShowOutput
        }
        else {
            if (($worktrees.Output -split '\r?\n') -contains 'branch refs/heads/main') {
                throw 'main is checked out in another worktree.'
            }
            Write-Host "dotfiles: updating main $($state.Main) -> $($state.Target)"
            $result = Invoke-DotfilesGit $Repository @('update-ref', 'refs/heads/main', $state.Target, $state.Main) -ShowOutput
        }
        if ($result.ExitCode -ne 0) { throw $result.Error }
        Write-Host 'dotfiles: main updated.'
        return $true
    }
    finally { Remove-Item -LiteralPath $lockPath -Force }
}

if ($CheckRepository) {
    try { Get-DotfilesUpdateState $CheckRepository | ConvertTo-Json -Compress }
    catch { [pscustomobject]@{ State = 'error'; Detail = $_.Exception.Message } | ConvertTo-Json -Compress }
}