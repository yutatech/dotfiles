$ErrorActionPreference = 'Stop'
if ($args.Count -eq 1 -and $args[0] -in @('-h', '--help')) {
    Write-Output 'Usage: git fixup <commit>'
    Write-Output '  Fix up a commit with staged changes and autosquash the result.'
    exit 0
}
if ($args.Count -ne 1 -or ([string]$args[0]).StartsWith('-')) {
    Write-Error 'Usage: git fixup <commit>'
    exit 1
}

$gitExecutable = (Get-Command git -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$commit = & $gitExecutable rev-parse --verify --end-of-options "$($args[0])^{commit}"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$parents = & $gitExecutable rev-list --parents -n 1 $commit
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$commitAndParents = $parents -split ' '
$isRoot = $commitAndParents.Count -eq 1

& $gitExecutable commit "--fixup=$commit"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$previousEditor = $env:GIT_SEQUENCE_EDITOR
try {
    $env:GIT_SEQUENCE_EDITOR = ':'
    if ($isRoot) {
        & $gitExecutable rebase -i --autosquash --autostash --root
    }
    else {
        & $gitExecutable rebase -i --autosquash --autostash $commitAndParents[1]
    }
    $result = $LASTEXITCODE
}
finally {
    $env:GIT_SEQUENCE_EDITOR = $previousEditor
}
exit $result
