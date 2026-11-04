$script:DotfilesRsyncPythonPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'rsync.py'

function rsync {
    $python = Get-Command python -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $python) {
        $python = Get-Command python3 -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -First 1
    }
    if (-not $python) {
        $global:LASTEXITCODE = 1
        Write-Error 'rsync: Python 3.10 or later is required (python or python3 on PATH).'
        return
    }

    & $python.Source -u $script:DotfilesRsyncPythonPath @args
    $global:LASTEXITCODE = $LASTEXITCODE
}

Register-ArgumentCompleter -CommandName rsync -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $prior = @($commandAst.CommandElements | Where-Object {
        $_.Extent.StartOffset -lt $cursorPosition -and $_.Extent.EndOffset -lt $cursorPosition
    } | Select-Object -Skip 1)
    $previous = if ($prior.Count -gt 0) { $prior[-1].Extent.Text.Trim("'`"") }
    if ($previous -eq '--log-level') {
        foreach ($level in @('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL')) {
            if ($level.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase)) {
                [System.Management.Automation.CompletionResult]::new(
                    $level, $level, 'ParameterValue', "Log level $level"
                )
            }
        }
        return
    }
    if ($previous -eq '--remote-shell') {
        foreach ($shell in @('auto', 'sh', 'cmd', 'powershell')) {
            if ($shell.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase)) {
                [System.Management.Automation.CompletionResult]::new(
                    $shell, $shell, 'ParameterValue', "Remote shell $shell"
                )
            }
        }
        return
    }
    if ($previous -in @('--port', '--modify-window', '--exclude', '--remote-python')) { return }
    if ($wordToComplete.StartsWith('-')) {
        foreach ($option in @(
            '-r', '--recursive', '-t', '--times', '-c', '--checksum', '-n', '--dry-run',
            '-v', '--verbose', '--no-verbose', '-q', '--quiet', '-h', '--human-readable',
            '--delete', '--exclude', '--progress', '--no-progress', '--stats',
            '--modify-window', '--port', '--remote-python', '--remote-shell', '--log-level',
            '--help'
        )) {
            if ($option.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase)) {
                [System.Management.Automation.CompletionResult]::new(
                    $option, $option, 'ParameterName', "rsync option $option"
                )
            }
        }
        return
    }

    $typedPath = $wordToComplete.Trim("'`"")
    if ($typedPath -match '^[^\\/:]+:' -and $typedPath -notmatch '^[A-Za-z]:') { return }
    $separator = $typedPath.LastIndexOfAny([char[]]@('\', '/'))
    $directory = if ($separator -ge 0) { $typedPath.Substring(0, $separator + 1) } else { '.' }
    $leaf = if ($separator -ge 0) { $typedPath.Substring($separator + 1) } else { $typedPath }
    Get-ChildItem -LiteralPath $directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name.StartsWith($leaf, [System.StringComparison]::OrdinalIgnoreCase) } |
        ForEach-Object {
            $completion = "'" + $_.FullName.Replace("'", "''") + "'"
            [System.Management.Automation.CompletionResult]::new(
                $completion, $_.Name, 'ProviderItem', $_.FullName
            )
        }
}