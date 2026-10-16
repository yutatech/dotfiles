$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$gitExecutable = (Get-Command git -CommandType Application | Select-Object -First 1).Source
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "dotfiles-git-$([guid]::NewGuid().ToString('N'))"
$previousConfig = $env:GIT_CONFIG_GLOBAL
$previousSystemConfig = $env:GIT_CONFIG_NOSYSTEM
$previousEditor = $env:GIT_SEQUENCE_EDITOR
$previousRepo = $env:DOTFILES_REPO_DIR

function Assert-Test {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Invoke-TestGit {
    & $gitExecutable @args
    if ($LASTEXITCODE -ne 0) { throw "Git failed: $args" }
}

New-Item -ItemType Directory -Path $testRoot | Out-Null
Push-Location $testRoot
try {
    $env:GIT_CONFIG_GLOBAL = Join-Path $testRoot 'empty-config'
    $env:GIT_CONFIG_NOSYSTEM = '1'
    $env:DOTFILES_REPO_DIR = $repoRoot
    Invoke-TestGit init --initial-branch=main
    Invoke-TestGit config user.name 'Dotfiles Test'
    Invoke-TestGit config user.email 'dotfiles-test@example.invalid'
    Invoke-TestGit config commit.gpgsign false
    Invoke-TestGit config core.autocrlf false
    Set-Content -LiteralPath 'sample.txt' -Value 'root'
    Invoke-TestGit add sample.txt
    Invoke-TestGit commit -m 'root commit'

    . (Join-Path $repoRoot 'setup_utils\pwsh.ps1')
    . (Join-Path $repoRoot 'git\pwsh.ps1')
    function Test-DotfilesGitConfiguration { return $false }
    function Read-Host { param([string]$Prompt); 'n' }
    $declinedOutput = @(git --version)
    Assert-Test ($declinedOutput.Count -eq 0) 'Git ran after setup was declined.'
    function Test-DotfilesGitConfiguration { return $true }

    $version = git --version
    Assert-Test ($version -match '^git version') 'Standard Git command was not forwarded.'
    $graph = @(git graph -1)
    Assert-Test ($LASTEXITCODE -eq 0 -and ($graph -join "`n") -match 'root commit') 'Graph command failed.'
    foreach ($command in @('clear', 'fixup')) {
        $helpText = @(git $command --help)
        Assert-Test ($LASTEXITCODE -eq 0 -and ($helpText -join "`n") -match "Usage: git $command") "Help failed: $command"
    }

    $completion = [System.Management.Automation.CommandCompletion]::CompleteInput('git fi', 6, $null)
    Assert-Test ($completion.CompletionMatches.CompletionText -contains 'fixup') 'Subcommand completion failed.'
    $completion = [System.Management.Automation.CommandCompletion]::CompleteInput('git fixup ', 10, $null)
    $rootHash = Invoke-TestGit rev-parse --short HEAD
    Assert-Test ($completion.CompletionMatches.CompletionText -contains $rootHash) 'Commit completion failed.'
    $inputLine = "git fixup $($rootHash.Substring(0, 3))"
    $completion = [System.Management.Automation.CommandCompletion]::CompleteInput($inputLine, $inputLine.Length, $null)
    Assert-Test ($completion.CompletionMatches.CompletionText -contains $rootHash) 'Partial commit completion failed.'

    $env:GIT_SEQUENCE_EDITOR = 'original-editor'
    Add-Content -LiteralPath 'sample.txt' -Value 'root fixup'
    Invoke-TestGit add sample.txt
    git fixup $rootHash
    Assert-Test ($LASTEXITCODE -eq 0) 'Root fixup failed.'
    Assert-Test ((Invoke-TestGit rev-list --count HEAD) -eq '1') 'Root fixup was not squashed.'
    Assert-Test ($env:GIT_SEQUENCE_EDITOR -eq 'original-editor') 'Sequence editor was not restored.'

    Add-Content -LiteralPath 'sample.txt' -Value 'second'
    Invoke-TestGit add sample.txt
    Invoke-TestGit commit -m 'second commit'
    $secondHash = Invoke-TestGit rev-parse --short HEAD
    Add-Content -LiteralPath 'sample.txt' -Value 'second fixup'
    Invoke-TestGit add sample.txt
    git fixup $secondHash
    Assert-Test ($LASTEXITCODE -eq 0) 'Non-root fixup failed.'
    Assert-Test ((Invoke-TestGit rev-list --count HEAD) -eq '2') 'Non-root fixup was not squashed.'

    $beforeInvalidFixup = Invoke-TestGit rev-parse HEAD
    git fixup missing-commit 2>&1 | Out-Null
    Assert-Test ($LASTEXITCODE -ne 0) 'Invalid commit was accepted.'
    Assert-Test ((Invoke-TestGit rev-parse HEAD) -eq $beforeInvalidFixup) 'Invalid fixup changed history.'

    Invoke-TestGit branch merged-feature
    Invoke-TestGit branch master
    Invoke-TestGit switch -c unmerged-feature
    Set-Content -LiteralPath 'unmerged.txt' -Value 'unmerged'
    Invoke-TestGit add unmerged.txt
    Invoke-TestGit commit -m 'unmerged change'
    Invoke-TestGit switch main
    git clear
    Assert-Test ($LASTEXITCODE -eq 0) 'Clear failed.'
    $branches = @(Invoke-TestGit for-each-ref '--format=%(refname:short)' refs/heads)
    Assert-Test ($branches -notcontains 'merged-feature') 'Merged feature was not deleted.'
    foreach ($branch in @('main', 'master', 'unmerged-feature')) {
        Assert-Test ($branches -contains $branch) "Protected or unmerged branch was deleted: $branch"
    }

    'PASS: setup refusal, dispatch, help, graph, completions, root/non-root fixup, invalid input, and clear.'
}
finally {
    Pop-Location
    $env:GIT_CONFIG_GLOBAL = $previousConfig
    $env:GIT_CONFIG_NOSYSTEM = $previousSystemConfig
    $env:GIT_SEQUENCE_EDITOR = $previousEditor
    $env:DOTFILES_REPO_DIR = $previousRepo
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}
