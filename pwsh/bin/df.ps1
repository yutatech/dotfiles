function ConvertFrom-DfBlockSize {
	param([string]$Value)

	if ($Value -match '^(\d+)([KMGTP]?)(?:i?B)?$') {
		$power = switch ($Matches[2].ToUpperInvariant()) {
			'K' { 1 }
			'M' { 2 }
			'G' { 3 }
			'T' { 4 }
			'P' { 5 }
			default { 0 }
		}
		return [double]$Matches[1] * [math]::Pow(1024, $power)
	}
	throw "df: invalid block size '$Value'."
}

function Format-DfSize {
	param([double]$Bytes, [double]$Unit)
	return [string][math]::Floor($Bytes / $Unit)
}

function Format-DfHumanSize {
	param([double]$Bytes, [bool]$Si)

	$base = if ($Si) { 1000.0 } else { 1024.0 }
	$suffixes = if ($Si) { @('B', 'kB', 'MB', 'GB', 'TB', 'PB') } else { @('B', 'K', 'M', 'G', 'T', 'P') }
	$index = 0
	while ($Bytes -ge $base -and $index -lt ($suffixes.Count - 1)) {
		$Bytes /= $base
		$index++
	}
	return ('{0:N1}{1}' -f $Bytes, $suffixes[$index])
}

function df {
	$ArgumentList = @($args)

	$unit = 1024.0
	$unitLabel = '1K-blocks'
	$humanMode = $null
	$showType = $false
	$total = $false
	$includeTypes = [System.Collections.Generic.List[string]]::new()
	$excludeTypes = [System.Collections.Generic.List[string]]::new()
	$paths = [System.Collections.Generic.List[string]]::new()

	for ($index = 0; $index -lt $ArgumentList.Count; $index++) {
		$argument = $ArgumentList[$index]
		if ($argument -eq '--') {
			for ($index++; $index -lt $ArgumentList.Count; $index++) { $paths.Add($ArgumentList[$index]) }
			break
		}
		if ($argument -in @('--help', '-help')) {
			Write-Output @(
				'使い方: df [オプション]... [ファイル]...'
				'ファイルが属するボリュームの容量、使用量、空き容量を表示します。'
				'ファイルを指定しない場合は、利用可能なすべてのボリュームを表示します。'
				''
				'オプション:'
				'  -a, --all                 すべての利用可能なボリュームを表示します。'
				'  -h, --human-readable      1024 を基準に読みやすい単位で表示します。'
				'  -H, --si                  1000 を基準に読みやすい単位で表示します。'
				'  -k                        1024 バイト単位で表示します（既定値）。'
				'  -m                        1 MiB 単位で表示します。'
				'  -B SIZE, --block-size=SIZE SIZE バイト単位で表示します。'
				'  -T, --print-type          ファイルシステムの種類を表示します。'
				'  -t TYPE, --type=TYPE      TYPE に一致する種類だけを表示します。'
				'  -x TYPE, --exclude-type=TYPE TYPE に一致する種類を除外します。'
				'  -P, --portability         POSIX 形式を指定します（この実装では表示は変わりません）。'
				'      --total               表示対象の容量を合計した行を追加します。'
				'      --help                このヘルプを表示します。'
				'      --version             バージョンを表示します。'
				''
				'SIZE は整数で、K、M、G、T、P（1024 の累乗）を末尾に付けられます。'
				'TYPE には * と ? を使ったワイルドカードを指定できます。'
				'Windows では -a は通常のボリューム一覧と同じ結果になります。'
			)
			return
		}
		if ($argument -eq '--version') { Write-Output 'df (PowerShell dotfiles) 1.0'; return }
		if ($argument -eq '--total') { $total = $true; continue }
		if ($argument -cin @('-h', '--human-readable')) { $humanMode = $false; continue }
		if ($argument -cin @('-H', '--si')) { $humanMode = $true; continue }
		if ($argument -match '^--block-size=(.+)$') { $unit = ConvertFrom-DfBlockSize $Matches[1]; $unitLabel = "$($Matches[1])-blocks"; continue }
		if ($argument -match '^--type=(.+)$') { $includeTypes.Add($Matches[1]); continue }
		if ($argument -match '^--exclude-type=(.+)$') { $excludeTypes.Add($Matches[1]); continue }
		if ($argument -cin @('-B', '--block-size', '-t', '--type', '-x', '--exclude-type')) {
			if (++$index -ge $ArgumentList.Count) { throw "df: option '$argument' requires an argument." }
			$value = $ArgumentList[$index]
			switch -CaseSensitive ($argument) {
				{ $_ -in @('-B', '--block-size') } { $unit = ConvertFrom-DfBlockSize $value; $unitLabel = "$value-blocks" }
				{ $_ -in @('-t', '--type') } { $includeTypes.Add($value) }
				{ $_ -in @('-x', '--exclude-type') } { $excludeTypes.Add($value) }
			}
			continue
		}
		if ($argument -match '^-[^-].*$') {
			$letters = $argument.Substring(1)
			for ($letterIndex = 0; $letterIndex -lt $letters.Length; $letterIndex++) {
				$option = $letters[$letterIndex]
				if ($option -cin @('B', 't', 'x')) {
					$value = $letters.Substring($letterIndex + 1)
					if (-not $value) {
						if (++$index -ge $ArgumentList.Count) { throw "df: option '-$option' requires an argument." }
						$value = $ArgumentList[$index]
					}
					switch -CaseSensitive ($option) {
						'B' { $unit = ConvertFrom-DfBlockSize $value; $unitLabel = "$value-blocks" }
						't' { $includeTypes.Add($value) }
						'x' { $excludeTypes.Add($value) }
					}
					break
				}
				switch -CaseSensitive ($option) {
					'a' { }
					'h' { $humanMode = $false }
					'H' { $humanMode = $true }
					'k' { $unit = 1024.0; $unitLabel = '1K-blocks'; $humanMode = $null }
					'm' { $unit = 1MB; $unitLabel = '1M-blocks'; $humanMode = $null }
					'P' { }
					'T' { $showType = $true }
					default { throw "df: unsupported option '-$option'." }
				}
			}
			continue
		}
		if ($argument.StartsWith('-')) { throw "df: unsupported option '$argument'." }
		$paths.Add($argument)
	}

	$volumes = [System.Collections.Generic.List[System.IO.DriveInfo]]::new()
	if ($paths.Count -eq 0) {
		foreach ($drive in [System.IO.DriveInfo]::GetDrives()) {
			if ($drive.IsReady) { $volumes.Add($drive) }
		}
	}
	else {
		foreach ($path in $paths) {
			try {
				$item = Get-Item -LiteralPath $path -ErrorAction Stop
				if ($item.PSProvider.Name -ne 'FileSystem') { throw 'not a filesystem path' }
				$root = [System.IO.Path]::GetPathRoot($item.FullName)
				$drive = [System.IO.DriveInfo]::new($root)
				if (-not $drive.IsReady) { throw 'volume is not ready' }
				if (-not ($volumes | Where-Object { $_.Name -eq $drive.Name })) { $volumes.Add($drive) }
			}
			catch {
				throw "df: cannot access '$path': $($_.Exception.Message)"
			}
		}
	}

	$rows = @(
		foreach ($drive in $volumes) {
			$type = $drive.DriveFormat
			if ($includeTypes.Count -gt 0 -and -not ($includeTypes | Where-Object { $type -like $_ })) { continue }
			if ($excludeTypes | Where-Object { $type -like $_ }) { continue }
			$used = $drive.TotalSize - $drive.AvailableFreeSpace
			$percent = if ($drive.TotalSize -gt 0) { [math]::Ceiling(100 * $used / $drive.TotalSize) } else { 0 }
			[pscustomobject]@{
				Filesystem = $drive.Name
				Type = $type
				TotalBytes = [double]$drive.TotalSize
				UsedBytes = [double]$used
				AvailableBytes = [double]$drive.AvailableFreeSpace
				UsePercent = $percent
			}
		}
	)

	$header = if ($humanMode -ne $null) { 'Filesystem Size Used Available Use% Mounted on' } else { "Filesystem $unitLabel Used Available Use% Mounted on" }
	if ($showType) { $header = $header.Replace('Filesystem ', 'Filesystem Type ') }
	Write-Output $header
	foreach ($row in $rows) {
		if ($humanMode -ne $null) {
			$blocks = Format-DfHumanSize $row.TotalBytes $humanMode
			$used = Format-DfHumanSize $row.UsedBytes $humanMode
			$available = Format-DfHumanSize $row.AvailableBytes $humanMode
		}
		else {
			$blocks = Format-DfSize $row.TotalBytes $unit
			$used = Format-DfSize $row.UsedBytes $unit
			$available = Format-DfSize $row.AvailableBytes $unit
		}
		if ($showType) {
			Write-Output ("{0} {1} {2} {3} {4} {5}% {0}" -f $row.Filesystem, $row.Type, $blocks, $used, $available, $row.UsePercent)
		}
		else {
			Write-Output ("{0} {1} {2} {3} {4}% {0}" -f $row.Filesystem, $blocks, $used, $available, $row.UsePercent)
		}
	}
	if ($total -and $rows.Count -gt 0) {
		$sumTotal = ($rows | Measure-Object -Property TotalBytes -Sum).Sum
		$sumUsed = ($rows | Measure-Object -Property UsedBytes -Sum).Sum
		$sumAvailable = ($rows | Measure-Object -Property AvailableBytes -Sum).Sum
		$percent = if ($sumTotal -gt 0) { [math]::Ceiling(100 * $sumUsed / $sumTotal) } else { 0 }
		if ($humanMode -ne $null) {
			$sumTotal = Format-DfHumanSize $sumTotal $humanMode
			$sumUsed = Format-DfHumanSize $sumUsed $humanMode
			$sumAvailable = Format-DfHumanSize $sumAvailable $humanMode
		}
		else {
			$sumTotal = Format-DfSize $sumTotal $unit
			$sumUsed = Format-DfSize $sumUsed $unit
			$sumAvailable = Format-DfSize $sumAvailable $unit
		}
		Write-Output ("total {0} {1} {2} {3}% -" -f $sumTotal, $sumUsed, $sumAvailable, $percent)
	}
}

Register-ArgumentCompleter -CommandName df -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)

	$prior = @($commandAst.CommandElements | Where-Object {
		$_.Extent.StartOffset -lt $cursorPosition -and $_.Extent.EndOffset -lt $cursorPosition
	} | Select-Object -Skip 1)
	$previous = if ($prior.Count -gt 0) { $prior[-1].Extent.Text.Trim("'`"") }
	if ($previous -in @('-B', '--block-size')) {
		foreach ($size in @('1K', '1M', '1G', '1KB', '1MB', '1GB')) {
			if ($size.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase)) {
				[System.Management.Automation.CompletionResult]::new($size, $size, 'ParameterValue', "Block size $size")
			}
		}
		return
	}
	if ($previous -in @('-t', '--type', '-x', '--exclude-type')) {
		[System.IO.DriveInfo]::GetDrives() | Where-Object IsReady | Select-Object -ExpandProperty DriveFormat -Unique |
			Where-Object { $_.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase) } |
			ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "Filesystem type $_") }
		return
	}
	if ($wordToComplete.StartsWith('-')) {
		foreach ($option in @('-a', '--all', '-h', '--human-readable', '-H', '--si', '-k', '-m', '-P', '--portability', '-T', '--print-type', '-B', '--block-size', '-t', '--type', '-x', '--exclude-type', '--total', '--help')) {
			if ($option.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase)) {
				[System.Management.Automation.CompletionResult]::new($option, $option, 'ParameterName', "df option $option")
			}
		}
		return
	}
	$typedPath = $wordToComplete.Trim("'`"")
	if ($typedPath -match '^[A-Za-z]:?\?$') {
		[System.IO.DriveInfo]::GetDrives() | Where-Object { $_.Name.StartsWith($typedPath, [System.StringComparison]::OrdinalIgnoreCase) } |
			ForEach-Object { [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ProviderItem', "Volume $($_.Name)") }
	}
	$separator = $typedPath.LastIndexOfAny([char[]]@('\', '/'))
	if ($separator -ge 0) {
		$directory = $typedPath.Substring(0, $separator + 1)
		$leaf = $typedPath.Substring($separator + 1)
		if (-not $directory) { $directory = '.' }
	}
	else {
		$directory = '.'
		$leaf = $typedPath
	}
	Get-ChildItem -LiteralPath $directory -Force -ErrorAction SilentlyContinue |
		Where-Object { $_.Name.StartsWith($leaf, [System.StringComparison]::OrdinalIgnoreCase) } |
		ForEach-Object {
			$completion = $_.FullName.Replace(' ', '` ')
			[System.Management.Automation.CompletionResult]::new($completion, $_.Name, 'ProviderItem', $_.FullName)
		}
}
