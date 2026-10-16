param([switch]$NoCheck)

$commandDirectory = Join-Path $env:DOTFILES_REPO_DIR 'dotfiles\cmd'
if (($env:PATH -split [IO.Path]::PathSeparator) -notcontains $commandDirectory) {
    $env:PATH = $commandDirectory + [IO.Path]::PathSeparator + $env:PATH
}

function global:dotfiles-update {
    try {
        . (Join-Path $env:DOTFILES_REPO_DIR 'dotfiles\scripts\dotfiles_update.ps1')
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

function global:Start-DotfilesUpdateCheck {
    param([string]$Repository, [string]$ScriptPath)

    $executable = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
    $startInfo = [Diagnostics.ProcessStartInfo]::new($executable)
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', $ScriptPath, '-CheckRepository', $Repository)) {
        $startInfo.ArgumentList.Add($argument)
    }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        $null = $process.Start()
        $process.StandardInput.Close()
        [pscustomobject]@{
            State = 'checking'; Handled = $false; Detail = ''; Target = ''
            Process = $process
            OutputTask = $process.StandardOutput.ReadToEndAsync()
            ErrorTask = $process.StandardError.ReadToEndAsync()
        }
    }
    catch { $process.Dispose(); throw }
}

function global:Write-DotfilesUpdateStatus {
    if (-not $global:DotfilesUpdateSession) { return }
    $previousExitCode = $global:LASTEXITCODE
    try {
        $session = $global:DotfilesUpdateSession
        if ($session.Process -and $session.Process.HasExited -and $session.OutputTask.IsCompleted -and $session.ErrorTask.IsCompleted) {
            try {
                $result = $session.OutputTask.GetAwaiter().GetResult() | ConvertFrom-Json -ErrorAction Stop
                if (-not $result.State -or $session.Process.ExitCode -ne 0) { throw 'Background check failed.' }
                $session.State = $result.State
                $session.Detail = $result.Detail
                $session.Target = $result.Target
            }
            catch { $session.State = 'error'; $session.Detail = 'Background check failed.' }
            finally {
                $session.Process.Dispose()
                $session.Process = $null
                $session.OutputTask = $null
                $session.ErrorTask = $null
            }
        }
        if ($session.State -eq 'available') {
            if (-not (Test-Path Function:Invoke-DotfilesGit)) {
                . (Join-Path $env:DOTFILES_REPO_DIR 'dotfiles\scripts\dotfiles_update.ps1')
            }
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
    try {
        $global:DotfilesUpdateSession = Start-DotfilesUpdateCheck $env:DOTFILES_REPO_DIR (Join-Path $env:DOTFILES_REPO_DIR 'dotfiles\scripts\dotfiles_update.ps1')
    }
    catch {
        $global:DotfilesUpdateSession = [pscustomobject]@{
            State = 'error'; Handled = $false; Detail = $_.Exception.Message; Target = ''
            Process = $null; OutputTask = $null; ErrorTask = $null
        }
    }
}