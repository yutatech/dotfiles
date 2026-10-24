Remove-Item Alias:kill -ErrorAction SilentlyContinue

function kill {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments = $true)]
        [string[]]$ArgumentList
    )

    $signal = 'TERM'
    $processIds = [System.Collections.Generic.List[string]]::new()
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
                throw 'kill: expected a signal after -s/--signal.'
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
                throw "kill: unsupported signal or option '$argument'. Supported signals are TERM and KILL."
            }
            continue
        }

        $processIds.Add($argument)
    }

    $signal = $signal.TrimStart('-').ToUpperInvariant()
    if ($signal -in @('9', 'KILL', 'SIGKILL')) {
        $force = $true
    }
    elseif ($signal -in @('15', 'TERM', 'SIGTERM')) {
        $force = $false
    }
    else {
        throw "kill: unsupported signal '$signal'. Supported signals are TERM and KILL."
    }

    if ($processIds.Count -eq 0) {
        throw 'kill: provide one or more process IDs.'
    }

    foreach ($processIdText in $processIds) {
        $processId = 0
        if (-not [int]::TryParse(
            $processIdText,
            [System.Globalization.NumberStyles]::None,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref]$processId
        ) -or $processId -le 0) {
            throw "kill: '$processIdText' is not a valid process ID."
        }

        Get-Process -Id $processId -ErrorAction Stop |
            Stop-Process -Force:$force -ErrorAction Stop
    }
}

Register-ArgumentCompleter -CommandName kill -ScriptBlock {
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
                    $option, $option, 'ParameterName', "kill option $option"
                )
            }
        }
        return
    }

    Get-Process -ErrorAction SilentlyContinue |
        Where-Object { "$($_.Id)".StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase) } |
        Sort-Object -Property Id |
        ForEach-Object {
            $id = "$($_.Id)"
            [System.Management.Automation.CompletionResult]::new(
                $id, "$id ($($_.ProcessName))", 'ParameterValue', "$($_.ProcessName) (PID $id)"
            )
        }
}