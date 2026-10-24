function pkill {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments = $true)]
        [string[]]$ArgumentList
    )

    $signal = 'TERM'
    $patterns = [System.Collections.Generic.List[string]]::new()
    $parseOptions = $true

    for ($i = 0; $i -lt $ArgumentList.Count; $i++) {
        $argument = $ArgumentList[$i]
        if ($parseOptions -and $argument -eq '--') {
            $parseOptions = $false
            continue
        }

        if ($parseOptions -and ($argument -eq '-s' -or $argument -eq '--signal')) {
            $i++
            if ($i -ge $ArgumentList.Count) {
                throw 'pkill: expected a signal after -s/--signal.'
            }
            $signal = $ArgumentList[$i]
            continue
        }

        if ($parseOptions -and $argument -match '^--signal=(.+)$') {
            $signal = $Matches[1]
            continue
        }

        if ($parseOptions -and $argument -match '^-(.+)$') {
            $option = $Matches[1].ToUpperInvariant()
            if ($option -in @('9', 'KILL', 'SIGKILL')) {
                $signal = 'KILL'
            }
            elseif ($option -in @('15', 'TERM', 'SIGTERM')) {
                $signal = 'TERM'
            }
            else {
                throw "pkill: unsupported signal or option '$argument'. Supported signals are TERM and KILL."
            }
            continue
        }

        $patterns.Add($argument)
    }

    $signal = $signal.TrimStart('-').ToUpperInvariant()
    if ($signal -in @('9', 'KILL', 'SIGKILL')) {
        $force = $true
    }
    elseif ($signal -in @('15', 'TERM', 'SIGTERM')) {
        $force = $false
    }
    else {
        throw "pkill: unsupported signal '$signal'. Supported signals are TERM and KILL."
    }

    if ($patterns.Count -ne 1) {
        throw 'pkill: provide exactly one process-name regular expression.'
    }

    $regex = [System.Text.RegularExpressions.Regex]::new($patterns[0])
    $processes = @(
        Get-Process -ErrorAction Stop |
            Where-Object { $_.Id -ne $PID -and $regex.IsMatch($_.ProcessName) }
    )
    if ($processes.Count -eq 0) {
        throw "pkill: no processes matched '$($patterns[0])'."
    }

    foreach ($process in $processes) {
        Stop-Process -InputObject $process -Force:$force -ErrorAction Stop
    }
}

Register-ArgumentCompleter -CommandName pkill -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $argumentsBeforeWord = @($commandAst.CommandElements | Where-Object {
        $_.Extent.StartOffset -lt $cursorPosition -and $_.Extent.EndOffset -lt $cursorPosition
    } | Select-Object -Skip 1)
    $previousArgument = if ($argumentsBeforeWord.Count -gt 0) {
        $argumentsBeforeWord[-1].Extent.Text.Trim("'`"")
    }

    if ($previousArgument -in @('-s', '--signal')) {
        foreach ($signal in @('TERM', 'KILL', 'SIGTERM', 'SIGKILL', '15', '9')) {
            if ($signal.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase)) {
                [System.Management.Automation.CompletionResult]::new(
                    $signal, $signal, 'ParameterValue', "Signal $signal"
                )
            }
        }
        return
    }

    if ($wordToComplete.StartsWith('-')) {
        foreach ($option in @('-s', '--signal', '-15', '-9', '-TERM', '-KILL')) {
            if ($option.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase)) {
                [System.Management.Automation.CompletionResult]::new(
                    $option, $option, 'ParameterName', "pkill option $option"
                )
            }
        }
        return
    }

    Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Id -ne $PID -and
            $_.ProcessName.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase)
        } |
        Select-Object -ExpandProperty ProcessName -Unique |
        Sort-Object |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_, $_, 'ParameterValue', "Process $_"
            )
        }
}