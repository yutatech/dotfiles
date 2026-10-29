Remove-Item Alias:open -ErrorAction SilentlyContinue

function open {
    $argumentList = @($args)
    $application = $null
    $targets = [System.Collections.Generic.List[string]]::new()
    $parseOptions = $true

    for ($index = 0; $index -lt $argumentList.Count; $index++) {
        $argument = $argumentList[$index]

        if ($parseOptions -and $argument -eq '--') {
            $parseOptions = $false
            continue
        }

        if ($parseOptions -and $argument -in @('--help', '-help', '-?')) {
            Write-Output @(
                '使い方: open [オプション]... ファイル|ディレクトリ|URL...'
                'ファイルやディレクトリを既定のアプリケーションで開くか、URL を既定のブラウザーで開きます。'
                ''
                'オプション:'
                '  -a APP, --application APP  指定したアプリケーションで開きます。'
                '      --application=APP      同上。'
                '      --help                 このヘルプを表示します。'
                '      --version              バージョンを表示します。'
                "      '--'                 以降の引数をファイル名として扱います（PowerShell では引用が必要です）。"
                ''
                '複数の対象を指定すると、それぞれを開きます。'
            )
            return
        }

        if ($parseOptions -and $argument -eq '--version') {
            Write-Output 'open (PowerShell dotfiles) 1.0'
            return
        }

        if ($parseOptions -and $argument -in @('-a', '--application')) {
            if (++$index -ge $argumentList.Count) {
                throw 'open: -a / --application にはアプリケーション名が必要です。'
            }
            if ($null -ne $application) {
                throw 'open: アプリケーションは一度だけ指定できます。'
            }
            $application = $argumentList[$index]
            if ([string]::IsNullOrWhiteSpace($application)) {
                throw 'open: アプリケーション名を空にはできません。'
            }
            continue
        }

        if ($parseOptions -and $argument -match '^--application=(.*)$') {
            if ($null -ne $application) {
                throw 'open: アプリケーションは一度だけ指定できます。'
            }
            $application = $Matches[1]
            if ([string]::IsNullOrWhiteSpace($application)) {
                throw 'open: アプリケーション名を空にはできません。'
            }
            continue
        }

        if ($parseOptions -and $argument.StartsWith('-')) {
            throw "open: 未対応のオプションです: '$argument'。ヘルプは 'open --help' を参照してください。"
        }

        $targets.Add($argument)
    }

    if ($targets.Count -eq 0) {
        throw "open: ファイル、ディレクトリ、または URL を指定してください。ヘルプは 'open --help' を参照してください。"
    }

    foreach ($target in $targets) {
        if ($null -eq $application) {
            Start-Process -FilePath $target -ErrorAction Stop
            continue
        }

        $quotedTarget = '"' + $target.Replace('"', '\"') + '"'
        Start-Process -FilePath $application -ArgumentList $quotedTarget -ErrorAction Stop
    }
}