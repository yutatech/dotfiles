$gitCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $gitExecutable = $global:DotfilesGitExecutable
    if (-not $gitExecutable) { return }

    $argumentsBeforeWord = @($commandAst.CommandElements | Where-Object {
        $_.Extent.StartOffset -lt $cursorPosition -and $_.Extent.EndOffset -lt $cursorPosition
    } | Select-Object -Skip 1 | ForEach-Object {
        $_.Extent.Text.Trim("'`"")
    })

    $globalOptionsWithValues = @(
        '-C', '-c', '--git-dir', '--work-tree', '--namespace', '--super-prefix',
        '--config-env', '--exec-path'
    )
    $commandIndex = -1
    for ($i = 0; $i -lt $argumentsBeforeWord.Count; $i++) {
        $argument = $argumentsBeforeWord[$i]
        if ($argument -eq '--') { break }
        if ($argument -in $globalOptionsWithValues) {
            $i++
            continue
        }
        if ($argument -match '^-(?:C|c).+' -or $argument -match '^--[^=]+=') {
            continue
        }
        if ($argument.StartsWith('-')) { continue }
        $commandIndex = $i
        break
    }
    if ($commandIndex -ge 0) {
        $gitPrefixArguments = @($argumentsBeforeWord | Select-Object -First $commandIndex)
    }
    else {
        $gitPrefixArguments = $argumentsBeforeWord
    }

    $emit = {
        param([string]$Text, [string]$ListItem, [string]$Type, [string]$Tooltip)
        [System.Management.Automation.CompletionResult]::new($Text, $ListItem, $Type, $Tooltip)
    }
    $matchesPrefix = {
        param([string]$Text)
        $Text.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase)
    }
    $getOptions = {
        param([string[]]$HelpLines, [switch]$ParseUsage)

        foreach ($line in $HelpLines) {
            if (-not $ParseUsage -and $line -notmatch '^\s+-') { continue }
            $optionMatches = [regex]::Matches(
                $line,
                '(?<![A-Za-z0-9])--(?:\[no-\])?[A-Za-z][A-Za-z0-9-]*|(?<![A-Za-z0-9])-[A-Za-z0-9](?![A-Za-z0-9])'
            )
            foreach ($optionMatch in $optionMatches) {
                $option = $optionMatch.Value
                if ($option.StartsWith('--[no-]')) {
                    $name = $option.Substring(7)
                    "--$name"
                    "--no-$name"
                }
                else {
                    $option
                }
            }
        }
    }

    if ($commandIndex -lt 0) {
        if ($wordToComplete.StartsWith('-')) {
            $globalHelp = @(& $gitExecutable.Source @gitPrefixArguments -h 2>$null)
            foreach ($option in (& $getOptions $globalHelp -ParseUsage | Sort-Object -Unique)) {
                if (& $matchesPrefix $option) {
                    & $emit $option $option 'ParameterName' "Git option $option"
                }
            }
            return
        }

        $commands = @(& $gitExecutable.Source @gitPrefixArguments --list-cmds=main,others,nohelpers,alias 2>$null)
        $commands += @('clear', 'fixup', 'graph')
        foreach ($name in $commands | Sort-Object -Unique) {
            if ($name -eq 'clear') { $description = 'Delete merged local branches' }
            elseif ($name -eq 'fixup') { $description = 'Fix up a commit with staged changes' }
            elseif ($name -eq 'graph') { $description = 'Show the commit graph' }
            else { $description = "Git $name command" }

            if (& $matchesPrefix $name) {
                & $emit $name $name 'ParameterValue' $description
            }
        }
        return
    }

    $command = $argumentsBeforeWord[$commandIndex]
    $commandArguments = @($argumentsBeforeWord | Select-Object -Skip ($commandIndex + 1))
    if ($command -in @('clear', 'graph')) { return }

    if ($command -eq 'fixup') {
        if ($commandArguments.Count -eq 0) {
            $commits = @(& $gitExecutable.Source @gitPrefixArguments --no-pager log -20 '--format=%h%x09%s' 2>$null)
            foreach ($commit in $commits) {
                $hash, $subject = $commit -split "`t", 2
                if (& $matchesPrefix $hash) {
                    & $emit $hash "$hash $subject" 'ParameterValue' "$hash $subject"
                }
            }
        }
        return
    }

    if ($wordToComplete.StartsWith('-') -and $commandArguments -notcontains '--') {
        $help = @(& $gitExecutable.Source @gitPrefixArguments $command -h 2>$null)
        foreach ($option in (& $getOptions $help | Sort-Object -Unique)) {
            if (& $matchesPrefix $option) {
                & $emit $option $option 'ParameterName' "$command option $option"
            }
        }
        return
    }

    if ($commandArguments -contains '--') { return }
    $positionalArguments = @($commandArguments | Where-Object { -not $_.StartsWith('-') })
    $candidateNames = @()
    $candidateType = 'Git reference'

    if ($command -eq 'stash' -and $positionalArguments.Count -eq 0) {
        $candidateNames = @('apply', 'branch', 'clear', 'drop', 'list', 'pop', 'push', 'show')
        $candidateType = 'Git stash command'
    }
    elseif ($command -eq 'stash' -and $positionalArguments[0] -in @('apply', 'drop', 'pop', 'show')) {
        $candidateNames = @(& $gitExecutable.Source @gitPrefixArguments stash list --format=%gd 2>$null)
        $candidateType = 'Git stash'
    }
    elseif ($command -eq 'remote' -and $positionalArguments.Count -eq 0) {
        $candidateNames = @('add', 'get-url', 'prune', 'remove', 'rename', 'set-head', 'set-branches', 'set-url', 'show', 'update')
        $candidateType = 'Git remote command'
    }
    elseif ($command -eq 'remote' -and $positionalArguments[0] -in @('remove', 'rm', 'rename', 'set-head', 'set-branches', 'set-url', 'show', 'prune', 'get-url')) {
        $candidateNames = @(& $gitExecutable.Source @gitPrefixArguments remote 2>$null)
        $candidateType = 'Git remote'
    }
    elseif ($command -in @('fetch', 'pull', 'push', 'ls-remote') -and $positionalArguments.Count -eq 0) {
        $candidateNames = @(& $gitExecutable.Source @gitPrefixArguments remote 2>$null)
        $candidateType = 'Git remote'
    }
    elseif ($command -in @('fetch', 'pull', 'push', 'ls-remote')) {
        $candidateNames = @(& $gitExecutable.Source @gitPrefixArguments for-each-ref '--format=%(refname:short)' refs/heads refs/remotes refs/tags 2>$null)
        $candidateType = 'Git reference'
    }
    elseif ($command -eq 'worktree' -and $positionalArguments.Count -eq 0) {
        $candidateNames = @('add', 'list', 'lock', 'move', 'prune', 'remove', 'repair', 'unlock')
        $candidateType = 'Git worktree command'
    }
    elseif ($command -eq 'worktree' -and $positionalArguments[0] -eq 'add' -and $positionalArguments.Count -ge 2) {
        $candidateNames = @(& $gitExecutable.Source @gitPrefixArguments for-each-ref '--format=%(refname:short)' refs/heads refs/remotes refs/tags 2>$null)
        $candidateType = 'Git reference'
    }
    elseif ($command -in @(
        'branch', 'checkout', 'switch', 'merge', 'rebase', 'reset', 'cherry-pick',
        'revert', 'show', 'log', 'diff', 'tag', 'worktree', 'restore'
    )) {
        $renamingBranch = (
            $command -eq 'branch' -and
            ($commandArguments -match '^-m$|^--move$|^-M$|^--force-rename$')
        )
        $creationOptions = @('-b', '-B', '-c', '-C', '--create', '--force-create', '--orphan')
        $needsBranchName = (
            $command -in @('checkout', 'switch') -and
            $commandArguments.Count -gt 0 -and
            $commandArguments[-1] -in $creationOptions
        )
        if (-not ($renamingBranch -or $needsBranchName)) {
            $candidateNames += @(& $gitExecutable.Source @gitPrefixArguments for-each-ref '--format=%(refname:short)' refs/heads refs/remotes refs/tags 2>$null)
            $candidateNames += @(& $gitExecutable.Source @gitPrefixArguments log -20 '--format=%h%x09%s' 2>$null) |
                ForEach-Object { ($_ -split "`t", 2)[0] }
            $candidateType = 'Git reference'
        }
    }

    foreach ($name in $candidateNames | Where-Object { $_ } | Sort-Object -Unique) {
        if (& $matchesPrefix $name) {
            & $emit $name $name 'ParameterValue' "$candidateType $name"
        }
    }
}

Register-ArgumentCompleter -Native -CommandName git -ScriptBlock $gitCompleter
