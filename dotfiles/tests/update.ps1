$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$gitExecutable = (Get-Command git -CommandType Application | Select-Object -First 1).Source
$bashExecutable = Get-Command bash -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
if (-not $bashExecutable -and $IsWindows) {
    $candidate = Join-Path (Split-Path -Parent $gitExecutable) '..\bin\bash.exe'
    if (Test-Path $candidate) { $bashExecutable = (Resolve-Path $candidate).Path }
}
$testRoot = Join-Path ([IO.Path]::GetTempPath()) "dotfiles-update-$([guid]::NewGuid().ToString('N'))"
$previousEnvironment = @{}
foreach ($name in @('GIT_CONFIG_GLOBAL', 'GIT_CONFIG_NOSYSTEM', 'DOTFILES_REPO_DIR', 'DOTFILES_TEST_ROOT')) {
    $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
}

function Assert-Test {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Invoke-TestGit {
    param([string]$Repository)
    $output = & $gitExecutable -C $Repository @args
    if ($LASTEXITCODE -ne 0) { throw "Git failed: $args" }
    $output
}

$engineScript = Join-Path $repoRoot 'dotfiles/scripts/dotfiles_update.ps1'

function Get-TestState {
    param([string]$Repository)
    if ($script:engine -eq 'PowerShell') { return (Get-DotfilesUpdateState $Repository).State }
    $env:DOTFILES_REPO_DIR = $Repository
    $output = & $bashExecutable $shellEngine check 2>$null
    return ($output -join '').Trim()
}

function Invoke-TestUpdate {
    param([string]$Repository)
    if ($script:engine -eq 'PowerShell') {
        try {
            $records = @(Invoke-DotfilesUpdate $Repository 6>&1)
            $script:updateLog = ($records | Where-Object { $_ -is [Management.Automation.InformationRecord] }) -join "`n"
            return $true
        }
        catch { return $false }
    }
    $env:DOTFILES_REPO_DIR = $Repository
    $records = @(& $bashExecutable $shellEngine update 2>&1)
    $script:updateLog = $records -join "`n"
    return $LASTEXITCODE -eq 0
}

function Push-TestCommit {
    param([string]$Repository, [string]$Message)
    Add-Content (Join-Path $Repository 'sample.txt') $Message
    $null = Invoke-TestGit $Repository add sample.txt
    $null = Invoke-TestGit $Repository commit -m $Message
    $null = Invoke-TestGit $Repository push
}

$null = New-Item -ItemType Directory $testRoot
try {
    $env:GIT_CONFIG_GLOBAL = Join-Path $testRoot 'config'
    $env:GIT_CONFIG_NOSYSTEM = '1'
    Set-Content $env:GIT_CONFIG_GLOBAL "[user]`n name = Dotfiles Test`n email = test@example.invalid`n[commit]`n gpgsign = false`n[core]`n autocrlf = false"
    $env:DOTFILES_REPO_DIR = $repoRoot
    . (Join-Path $repoRoot 'dotfiles/update.ps1') -NoCheck
    Assert-Test (-not (Test-Path Function:Invoke-DotfilesGit)) 'Update engine was loaded eagerly.'
    . $engineScript
    $records = @(Invoke-DotfilesGit $repoRoot @('--version') -ShowOutput 6>&1)
    Assert-Test (($records | Where-Object { $_ -is [Management.Automation.InformationRecord] }) -match 'git version') 'Git stdout was not displayed.'
    $records = @(Invoke-DotfilesGit $repoRoot @('not-a-real-subcommand') -ShowOutput 6>&1)
    Assert-Test (($records | Where-Object { $_ -is [Management.Automation.InformationRecord] }) -match 'not-a-real-subcommand') 'Git stderr was not displayed.'
    $shellEngine = (Join-Path $repoRoot 'dotfiles/scripts/dotfiles_update.sh').Replace('\', '/')
    $engines = @('PowerShell')
    if ($bashExecutable) { $engines += 'bash' }
    else { Write-Warning 'bash unavailable; shell engine runtime tests skipped.' }

    foreach ($script:engine in $engines) {
        $fixture = Join-Path $testRoot $engine
        $null = New-Item -ItemType Directory $fixture
        $remote = Join-Path $fixture 'remote'
        $local = Join-Path $fixture 'local'
        $peer = Join-Path $fixture 'peer'
        $null = Invoke-TestGit $fixture init --bare --initial-branch=main $remote
        $null = Invoke-TestGit $fixture clone $remote $local
        Set-Content (Join-Path $local 'sample.txt') initial
        $null = Invoke-TestGit $local add sample.txt
        $null = Invoke-TestGit $local commit -m initial
        $null = Invoke-TestGit $local push -u origin main
        $null = Invoke-TestGit $local remote rename origin upstream
        $null = Invoke-TestGit $fixture clone $remote $peer
        Assert-Test ((Get-TestState $local) -eq 'current') "${engine}: initial state is not current."
        $before = Invoke-TestGit $local rev-parse main
        Push-TestCommit $peer next
        Assert-Test ((Get-TestState $local) -eq 'available') "${engine}: update not detected."
        Assert-Test ((Invoke-TestGit $local rev-parse main) -eq $before) "${engine}: check changed main."

        $env:DOTFILES_REPO_DIR = $local
        $env:DOTFILES_TEST_ROOT = $repoRoot.Replace('\', '/')
        if ($engine -eq 'PowerShell') {
            . (Join-Path $repoRoot 'dotfiles/update.ps1') -NoCheck
            $script:confirmationCount = 0
            function Read-Host { param([string]$Prompt); $script:confirmationCount++; 'N' }
            $global:DotfilesUpdateSession = Start-DotfilesUpdateCheck $local $engineScript
            Assert-Test ($global:DotfilesUpdateSession.State -eq 'checking') 'Check did not start asynchronously.'
            Assert-Test (@(Get-Job).Count -eq 0) 'Background check created a PowerShell job.'
            Assert-Test ($global:DotfilesUpdateSession.Process.WaitForExit(20000)) 'Background check timed out.'
            [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($global:DotfilesUpdateSession.OutputTask, $global:DotfilesUpdateSession.ErrorTask))
            Write-DotfilesUpdateStatus
            Write-DotfilesUpdateStatus
            Assert-Test ($script:confirmationCount -eq 1) 'PowerShell confirmation was not session-scoped.'
            Assert-Test ($global:DotfilesUpdateSession.State -eq 'available') 'Declining cleared the update marker.'
            Assert-Test ($null -eq $global:DotfilesUpdateSession.Process) 'Background process was not cleaned up.'
            $updateFunction = (Get-Item Function:dotfiles-update).ScriptBlock
            $script:acceptedUpdates = 0
            function dotfiles-update { $script:acceptedUpdates++ }
            function Read-Host { param([string]$Prompt); 'y' }
            $global:DotfilesUpdateSession.Handled = $false
            Write-DotfilesUpdateStatus
            Write-DotfilesUpdateStatus
            Assert-Test ($script:acceptedUpdates -eq 1) 'PowerShell approval did not run exactly one update.'
            Set-Item Function:dotfiles-update -Value $updateFunction
        }
        else {
            $promptTest = @'
DOTFILES_UPDATE_INITIALIZED=1
DOTFILES_UPDATE_STATE=available
PROMPT_COMMAND=': existing-hook'
. "$DOTFILES_TEST_ROOT/dotfiles/update.sh"
[[ "$PROMPT_COMMAND" == *'existing-hook'* ]] || exit 1
_dotfiles_update_prompt <<< N
_dotfiles_update_prompt
[ "$DOTFILES_UPDATE_STATE" = available ] || exit 2
false
_dotfiles_update_prompt
[ "$?" = 1 ] || exit 3
PROMPT_COMMAND=(': array-hook')
. "$DOTFILES_TEST_ROOT/dotfiles/update.sh"
[ "${PROMPT_COMMAND[1]}" = ': array-hook' ] || exit 4
dotfiles-update() { printf '%s\n' ACCEPTED; }
DOTFILES_UPDATE_HANDLED=0
_dotfiles_update_prompt <<< y
_dotfiles_update_prompt
'@
            $output = & $bashExecutable --noprofile --norc -ic $promptTest 2>$null
            Assert-Test ($LASTEXITCODE -eq 0) 'bash prompt, hook preservation, or exit status failed.'
            Assert-Test (([regex]::Matches(($output -join "`n"), 'Update dotfiles main now')).Count -eq 2) 'bash confirmation was not session-scoped.'
            Assert-Test (([regex]::Matches(($output -join "`n"), 'ACCEPTED')).Count -eq 1) 'bash approval did not run exactly one update.'
            $startupTest = @'
disown() { :; }
. "$DOTFILES_TEST_ROOT/dotfiles/update.sh"
[ "$DOTFILES_UPDATE_STATE" = checking ] || exit 1
previous_temp=$DOTFILES_UPDATE_TEMP
. "$DOTFILES_TEST_ROOT/dotfiles/update.sh"
[ "$DOTFILES_UPDATE_TEMP" = "$previous_temp" ] || exit 2
wait
_dotfiles_update_prompt <<< N
[ "$DOTFILES_UPDATE_STATE" = available ] || exit 3
[ -z "$DOTFILES_UPDATE_TEMP" ] || exit 4
_dotfiles_update_prompt
'@
            $output = & $bashExecutable --noprofile --norc -ic $startupTest 2>$null
            Assert-Test ($LASTEXITCODE -eq 0) 'bash asynchronous startup or result cleanup failed.'
            Assert-Test (([regex]::Matches(($output -join "`n"), 'Update dotfiles main now')).Count -eq 1) 'bash startup confirmation was repeated.'
        }

        $lockPath = Join-Path $local '.git/dotfiles-update.lock'
        $null = New-Item -ItemType Directory $lockPath
        Assert-Test (-not (Invoke-TestUpdate $local)) "${engine}: concurrent update was accepted."
        Assert-Test (Test-Path $lockPath) "${engine}: another update lock was removed."
        Remove-Item $lockPath
        Set-Content (Join-Path $local 'untracked.txt') dirty
        Assert-Test (-not (Invoke-TestUpdate $local)) "${engine}: untracked changes were accepted."
        Remove-Item (Join-Path $local 'untracked.txt')
        Add-Content (Join-Path $local 'sample.txt') dirty
        Assert-Test (-not (Invoke-TestUpdate $local)) "${engine}: tracked changes were accepted."
        Assert-Test ((Invoke-TestGit $local rev-parse main) -eq $before) "${engine}: refused update changed main."
        $null = Invoke-TestGit $local restore sample.txt
        Assert-Test (Invoke-TestUpdate $local) "${engine}: clean fast-forward failed."
        Assert-Test ($script:updateLog -match 'Fast-forward') "${engine}: fast-forward output was not displayed."
        Assert-Test ($script:updateLog -match 'up to date|upstream/main') "${engine}: fetch output was not displayed."
        Assert-Test ((Get-TestState $local) -eq 'current') "${engine}: update did not reach upstream."
        if ($engine -eq 'PowerShell') {
            Write-DotfilesUpdateStatus
            Assert-Test ($global:DotfilesUpdateSession.State -eq 'current') 'Stale update marker was not cleared.'
        }

        Push-TestCommit $peer feature-update
        $null = Invoke-TestGit $local switch -c feature
        $featureHead = Invoke-TestGit $local rev-parse HEAD
        Set-Content (Join-Path $local 'sample.txt') 'dirty feature contents'
        Assert-Test (Invoke-TestUpdate $local) "${engine}: main reference update on feature failed."
        Assert-Test ((Invoke-TestGit $local rev-parse HEAD) -eq $featureHead) "${engine}: feature HEAD changed."
        Assert-Test ((Get-Content (Join-Path $local 'sample.txt')) -eq 'dirty feature contents') "${engine}: feature contents changed."
        Assert-Test ((Invoke-TestGit $local rev-parse main) -eq (Invoke-TestGit $peer rev-parse main)) "${engine}: main reference was not advanced."
        $null = Invoke-TestGit $local restore sample.txt

        $worktree = Join-Path $fixture 'worktree'
        $null = Invoke-TestGit $local worktree add $worktree main
        Push-TestCommit $peer worktree-update
        $before = Invoke-TestGit $local rev-parse main
        Assert-Test (-not (Invoke-TestUpdate $local)) "${engine}: active main worktree was ignored."
        Assert-Test ((Invoke-TestGit $local rev-parse main) -eq $before) "${engine}: worktree refusal changed main."
        $null = Invoke-TestGit $local worktree remove $worktree
        Assert-Test (Invoke-TestUpdate $local) "${engine}: update failed after worktree removal."

        $null = Invoke-TestGit $local switch main
        Add-Content (Join-Path $local 'sample.txt') local-only
        $null = Invoke-TestGit $local add sample.txt
        $null = Invoke-TestGit $local commit -m local-only
        Push-TestCommit $peer remote-only
        Assert-Test ((Get-TestState $local) -eq 'diverged') "${engine}: divergence not detected."
        Assert-Test (-not (Invoke-TestUpdate $local)) "${engine}: divergent main was updated."
        $null = Invoke-TestGit $local config --unset branch.main.remote
        Assert-Test ((Get-TestState $local) -eq 'error') "${engine}: missing upstream was not an error."
        $null = Invoke-TestGit $local config branch.main.remote upstream
        $null = Invoke-TestGit $local remote set-url upstream (Join-Path $fixture 'missing-remote')
        Assert-Test ((Get-TestState $local) -eq 'error') "${engine}: failed fetch was not an error."
        Assert-Test (-not (Test-Path (Join-Path $local '.git/dotfiles-update.lock'))) "${engine}: update lock leaked."
        "PASS: ${engine}: upstream, background/confirmation, dirty tree, fast-forward, feature safety, worktree refusal, divergence, fetch failure."
    }

    $reloadRoot = Join-Path $testRoot 'reload'
    $null = New-Item -ItemType Directory (Join-Path $reloadRoot 'dotfiles/scripts') -Force
    Set-Content (Join-Path $reloadRoot 'dotfile.ps1') 'function Test-DotfilesReloaded { return "reloaded" }'
    Set-Content (Join-Path $reloadRoot 'dotfiles/scripts/dotfiles_update.ps1') 'function Invoke-DotfilesUpdate { return $true }'
    $env:DOTFILES_REPO_DIR = $reloadRoot
    dotfiles-update
    Assert-Test ((Test-DotfilesReloaded) -eq 'reloaded') 'Reloaded functions did not persist after returning.'
    Remove-Item Function:Test-DotfilesReloaded
    'PASS: PowerShell configuration reload persists after the update function returns.'
}
finally {
    if ($global:DotfilesUpdateSession.Process) {
        if (-not $global:DotfilesUpdateSession.Process.HasExited) { $global:DotfilesUpdateSession.Process.Kill($true) }
        $global:DotfilesUpdateSession.Process.Dispose()
    }
    foreach ($name in $previousEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name])
    }
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}