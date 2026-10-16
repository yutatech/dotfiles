$ErrorActionPreference = 'Stop'
if ($args.Count -eq 1 -and $args[0] -in @('-h', '--help')) {
    Write-Output 'Usage: git clear'
    Write-Output '  Fetch and prune, then delete merged local branches except main, master, and the current branch.'
    exit 0
}
if ($args.Count -ne 0) {
    Write-Error 'Usage: git clear'
    exit 1
}

$gitExecutable = (Get-Command git -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
& $gitExecutable fetch --prune
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$refs = @(& $gitExecutable for-each-ref '--format=%(refname:short)' refs/heads refs/remotes)
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$defaultBranch = @('origin/main', 'origin/master', 'main', 'master') |
    Where-Object { $_ -cin $refs } | Select-Object -First 1
if (-not $defaultBranch) {
    Write-Error 'No default branch found (origin/main, origin/master, main, or master).'
    exit 1
}

$branches = @(& $gitExecutable branch --merged $defaultBranch '--format=%(refname:short)|%(HEAD)')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$deleted = $false
foreach ($branch in $branches) {
    $name, $current = $branch -split '\|', 2
    if ($current -eq '*' -or $name -cin @('main', 'master')) { continue }
    & $gitExecutable branch -D -- $name
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $deleted = $true
}
if (-not $deleted) { Write-Output 'No merged local branch' }
exit 0
