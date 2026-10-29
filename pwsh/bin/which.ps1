Remove-Item Alias:which -ErrorAction SilentlyContinue

function which {
    $argumentList = @($args)
    $showAll = $false
    $commandNames = [System.Collections.Generic.List[string]]::new()
    $parseOptions = $true

    for ($index = 0; $index -lt $argumentList.Count; $index++) {
        $argument = $argumentList[$index]

        if ($parseOptions -and $argument -eq '--') {
            $parseOptions = $false
            continue
        }

        if ($parseOptions -and $argument -in @('--help', '-help', '-?')) {
            Write-Output @(
                '使い方: which [オプション]... コマンド...'
                'PowerShell が解決するコマンドの場所または種類を表示します。'
                ''
                'オプション:'
                '  -a, --all       同名のコマンドをすべて表示します。'
                '      --help      このヘルプを表示します。'
                '      --version   バージョンを表示します。'
                '      --          以降の引数をコマンド名として扱います。'
                ''
                '実行ファイルとスクリプトはパスを表示します。'
                'エイリアス、関数、コマンドレットなどは種類と名前を表示します。'
            )
            return
        }

        if ($parseOptions -and $argument -eq '--version') {
            Write-Output 'which (PowerShell dotfiles) 1.0'
            return
        }

        if ($parseOptions -and $argument -in @('-a', '--all')) {
            $showAll = $true
            continue
        }

        if ($parseOptions -and $argument.StartsWith('-')) {
            throw "which: 未対応のオプションです: '$argument'。ヘルプは 'which --help' を参照してください。"
        }

        $commandNames.Add($argument)
    }

    if ($commandNames.Count -eq 0) {
        throw "which: コマンド名を指定してください。ヘルプは 'which --help' を参照してください。"
    }

    foreach ($commandName in $commandNames) {
        $escapedName = [System.Management.Automation.WildcardPattern]::Escape($commandName)
        $commands = if ($showAll) {
            @(Get-Command -Name $escapedName -All -ErrorAction SilentlyContinue)
        }
        else {
            @(Get-Command -Name $escapedName -ErrorAction SilentlyContinue)
        }

        if ($commands.Count -eq 0) {
            throw "which: コマンドが見つかりません: '$commandName'"
        }

        foreach ($command in $commands) {
            switch ($command.CommandType) {
                { $_ -in @('Application', 'ExternalScript', 'Script') } {
                    if (-not [string]::IsNullOrEmpty($command.Path)) {
                        Write-Output $command.Path
                    }
                    else {
                        Write-Output "$($command.CommandType): $($command.Name)"
                    }
                    break
                }
                'Alias' {
                    Write-Output "Alias: $($command.Name) -> $($command.Definition)"
                    break
                }
                'Cmdlet' {
                    if (-not [string]::IsNullOrEmpty($command.Source)) {
                        Write-Output "Cmdlet: $($command.Name) ($($command.Source))"
                    }
                    else {
                        Write-Output "Cmdlet: $($command.Name)"
                    }
                    break
                }
                default {
                    Write-Output "$($command.CommandType): $($command.Name)"
                }
            }
        }
    }
}