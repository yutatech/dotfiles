$gitCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $elements = @($commandAst.CommandElements | Where-Object {
        $_.Extent.StartOffset -lt $cursorPosition
    })
    $argumentsBeforeWord = @($elements | Select-Object -Skip 1 | Where-Object {
        $_.Extent.EndOffset -lt $cursorPosition
    })

    if ($argumentsBeforeWord.Count -eq 0) {
        $commands = [ordered]@{
            clear = 'Delete merged local branches'
            fixup = 'Fix up a commit with staged changes'
            graph = 'Show the commit graph'
        }
        foreach ($name in $commands.Keys) {
            if ($name.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase)) {
                [System.Management.Automation.CompletionResult]::new(
                    $name, $name, 'ParameterValue', $commands[$name]
                )
            }
        }
        return
    }

    if ($argumentsBeforeWord.Count -eq 1 -and $argumentsBeforeWord[0].Extent.Text -eq 'fixup') {
        $commits = @(& $global:DotfilesGitExecutable.Source --no-pager log -20 '--format=%h%x09%s' 2>$null)
        if ($LASTEXITCODE -ne 0) { return }
        foreach ($commit in $commits) {
            $hash, $subject = $commit -split "`t", 2
            if ($hash.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase)) {
                [System.Management.Automation.CompletionResult]::new(
                    $hash, "$hash $subject", 'ParameterValue', "$hash $subject"
                )
            }
        }
    }
}

Register-ArgumentCompleter -Native -CommandName git -ScriptBlock $gitCompleter
