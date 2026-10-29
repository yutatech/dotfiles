Remove-Item Alias:ls -ErrorAction SilentlyContinue

function Format-LsSize {
	param([long]$Bytes)

	$units = @('B', 'K', 'M', 'G', 'T', 'P')
	$value = [double]$Bytes
	$index = 0
	while ($value -ge 1024 -and $index -lt ($units.Count - 1)) {
		$value /= 1024
		$index++
	}
	if ($index -eq 0) { return [string]$Bytes }
	return ('{0:N1}{1}' -f $value, $units[$index])
}

function Get-LsMode {
	param([object]$Item)

	$attributes = if ($Item.PSObject.Properties['Attributes']) { [System.IO.FileAttributes]$Item.Attributes } else { [System.IO.FileAttributes]0 }
	$isDirectory = $Item -is [System.IO.DirectoryInfo] -or $Item.IsDirectory
	$type = if ($isDirectory) { 'd' } else { '-' }
	if ($attributes -band [System.IO.FileAttributes]::ReparsePoint) { $type = 'l' }
	$write = if ($Item.IsReadOnly) { '-' } else { 'w' }
	$extension = if ($Item.PSObject.Properties['Extension']) { $Item.Extension } else { '' }
	$execute = if ($isDirectory -or $extension -in @('.exe', '.com', '.bat', '.cmd', '.ps1')) { 'x' } else { '-' }
	return ($type + 'r' + $write + $execute + 'r-' + $execute + 'r-' + $execute)
}

function Format-LsLongEntry {
	param(
	[object]$Item,
		[bool]$HumanReadable,
		[string]$DisplayName
	)

	$mode = Get-LsMode $Item
	$size = if ($Item -is [System.IO.DirectoryInfo] -or $Item.IsDirectory) { 0L } elseif ($Item.PSObject.Properties['Length']) { [long]$Item.Length } else { 0L }
	$sizeText = if ($HumanReadable) { Format-LsSize $size } else { [string]$size }
	$dateText = $Item.LastWriteTime.ToString('yyyy-MM-dd HH:mm', [System.Globalization.CultureInfo]::InvariantCulture)
	$name = if ($DisplayName) { $DisplayName } else { $Item.Name }
	if ($Item.PSObject.Properties['Attributes'] -and $Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
		try { $name += " -> $($Item.Target)" } catch { }
	}
	return ('{0} 1 {1} {2} {3,8} {4} {5}' -f $mode, $env:USERNAME, $env:USERDOMAIN, $sizeText, $dateText, $name)
}

function Write-LsEntries {
	param(
		[object[]]$Entries,
		[bool]$LongFormat,
		[bool]$HumanReadable,
		[bool]$SingleColumn,
		[string[]]$Names
	)

	if ($Entries.Count -eq 0) { return }
	if ($LongFormat) {
		for ($index = 0; $index -lt $Entries.Count; $index++) {
			$entry = $Entries[$index]
			if ($entry -is [string]) { Write-Output $entry }
			else {
				$name = if ($Names -and $index -lt $Names.Count) { $Names[$index] } else { $null }
				Write-Output (Format-LsLongEntry $entry $HumanReadable $name)
			}
		}
		return
	}
	if ($SingleColumn -or [Console]::IsOutputRedirected) {
		for ($index = 0; $index -lt $Entries.Count; $index++) {
			$entry = $Entries[$index]
			$name = if ($Names -and $index -lt $Names.Count) { $Names[$index] } else { $null }
			if ($entry -is [string]) { Write-Output $entry }
			elseif ($name) { Write-Output $name }
			else { Write-Output $entry.Name }
		}
		return
	}

	$names = @(
		for ($index = 0; $index -lt $Entries.Count; $index++) {
			if ($Names -and $index -lt $Names.Count) { $Names[$index] }
			elseif ($Entries[$index] -is [string]) { $Entries[$index] }
			else { $Entries[$index].Name }
		}
	)
	$width = 80
	try { if ([Console]::WindowWidth -gt 0) { $width = [Console]::WindowWidth } } catch { }
	$cellWidth = [math]::Max(1, (($names | Measure-Object -Property Length -Maximum).Maximum + 2))
	$columnCount = [math]::Max(1, [math]::Floor($width / $cellWidth))
	$rowCount = [math]::Ceiling($names.Count / $columnCount)
	for ($row = 0; $row -lt $rowCount; $row++) {
		$cells = [System.Collections.Generic.List[string]]::new()
		for ($column = 0; $column -lt $columnCount; $column++) {
			$index = $column * $rowCount + $row
			if ($index -lt $names.Count) { $cells.Add($names[$index]) }
		}
		for ($column = 0; $column -lt $cells.Count; $column++) {
			if ($column -lt ($cells.Count - 1)) { $cells[$column] = $cells[$column].PadRight($cellWidth) }
		}
		Write-Output ($cells -join '')
	}
}

function ls {
	$argumentList = @($args)
	$showAll = $false
	$almostAll = $false
	$longFormat = $false
	$humanReadable = $false
	$recursive = $false
	$reverse = $false
	$sortByTime = $false
	$sortBySize = $false
	$directoryOnly = $false
	$singleColumn = $false
	$paths = [System.Collections.Generic.List[string]]::new()
	$parseOptions = $true

	for ($index = 0; $index -lt $argumentList.Count; $index++) {
		$argument = $argumentList[$index]
		if ($parseOptions -and $argument -eq '--') { $parseOptions = $false; continue }
		if ($parseOptions -and $argument -in @('--help', '-help', '-?')) {
			Write-Output @(
				'使い方: ls [オプション]... [ファイル]...'
				'ファイルやディレクトリの情報を一覧表示します。'
				'ファイルを指定しない場合は、カレントディレクトリを表示します。'
				''
				'オプション:'
				'  -a, --all             . と .. を含むすべての項目を表示します。'
				'  -A, --almost-all      . と .. を除く隠し項目を表示します。'
				'  -d, --directory       ディレクトリの内容ではなくディレクトリ自体を表示します。'
				'  -h, --human-readable  -l のサイズを読みやすい単位で表示します。'
				'  -l                    詳細形式で表示します。'
				'  -R, --recursive       サブディレクトリを再帰的に表示します。'
				'  -r, --reverse         表示順を逆にします。'
				'  -S                    ファイルサイズの降順で並べます。'
				'  -t                    更新日時の降順で並べます。'
				'  -1                    1行に1項目ずつ表示します。'
				'      --help            このヘルプを表示します。'
				'      --version         バージョンを表示します。'
				''
				'端末では列表示、リダイレクト時は1行に1項目ずつ表示します。'
				'Windows の属性・所有者情報を使うため、GNU Coreutils と完全互換ではありません。'
			)
			return
		}
		if ($parseOptions -and $argument -eq '--version') { Write-Output 'ls (PowerShell dotfiles) 1.0'; return }
		if ($parseOptions -and $argument.StartsWith('-') -and $argument -ne '-') {
			if ($argument.StartsWith('--')) {
				switch -CaseSensitive ($argument) {
					'--all' { $showAll = $true }
					'--almost-all' { $almostAll = $true }
					'--directory' { $directoryOnly = $true }
					'--human-readable' { $humanReadable = $true }
					'--recursive' { $recursive = $true }
					'--reverse' { $reverse = $true }
					'--help' { }
					default { throw "ls: 未対応のオプションです: '$argument'。ヘルプは 'ls --help' を参照してください。" }
				}
				continue
			}
			if ($argument -match '^-[^-].*$') {
				foreach ($option in $argument.Substring(1).ToCharArray()) {
					switch -CaseSensitive ([string]$option) {
						'a' { $showAll = $true }
						'A' { $almostAll = $true }
						'd' { $directoryOnly = $true }
						'h' { $humanReadable = $true }
						'l' { $longFormat = $true }
						'R' { $recursive = $true }
						'r' { $reverse = $true }
						'S' { $sortBySize = $true }
						't' { $sortByTime = $true }
						'1' { $singleColumn = $true }
						default { throw "ls: 未対応のオプションです: '-$option'。ヘルプは 'ls --help' を参照してください。" }
					}
				}
				continue
			}
		}
		$paths.Add($argument)
	}

	if ($paths.Count -eq 0) { $paths.Add('.') }
	$multiple = $paths.Count -gt 1
	$firstOutput = $true

	foreach ($path in $paths) {
		try { $items = @(Get-Item -Path $path -Force -ErrorAction Stop) }
		catch { Write-Error "ls: '$path' にアクセスできません: $($_.Exception.Message)"; continue }

		foreach ($item in $items) {
			if ($item -isnot [System.IO.DirectoryInfo] -or $directoryOnly) {
				if (-not $firstOutput) { Write-Output '' }
				$displayName = if ($path.IndexOfAny([char[]]@('*', '?', '[')) -ge 0) { $item.Name } else { $path }
				Write-LsEntries -Entries @($item) -LongFormat $longFormat -HumanReadable $humanReadable -SingleColumn $singleColumn -Names @($displayName)
				$firstOutput = $false
				continue
			}

			$queue = [System.Collections.Generic.Queue[System.IO.DirectoryInfo]]::new()
			$queue.Enqueue($item)
			while ($queue.Count -gt 0) {
				$directory = $queue.Dequeue()
				if ($multiple -or $recursive) {
					if (-not $firstOutput) { Write-Output '' }
					Write-Output "$($directory.FullName):"
				}
				$entries = @(Get-ChildItem -LiteralPath $directory.FullName -Force -ErrorAction SilentlyContinue | Where-Object {
					$showAll -or $almostAll -or -not $_.Name.StartsWith('.')
				} | Sort-Object -Property Name)
				if ($showAll) {
					$parent = if ($directory.Parent) { $directory.Parent } else { $directory }
					$dotEntries = @(
						[pscustomobject]@{ Name = '.'; IsDirectory = $true; Attributes = [System.IO.FileAttributes]::Directory; IsReadOnly = $directory.IsReadOnly; LastWriteTime = $directory.LastWriteTime; Length = 0L }
						[pscustomobject]@{ Name = '..'; IsDirectory = $true; Attributes = [System.IO.FileAttributes]::Directory; IsReadOnly = $parent.IsReadOnly; LastWriteTime = $parent.LastWriteTime; Length = 0L }
					)
					$entries = $dotEntries + $entries
				}
				if ($sortByTime) { $entries = @($entries | Sort-Object -Property LastWriteTime -Descending) }
				if ($sortBySize) { $entries = @($entries | Sort-Object -Property Length -Descending) }
				if ($reverse) { [array]::Reverse($entries) }
				Write-LsEntries -Entries $entries -LongFormat $longFormat -HumanReadable $humanReadable -SingleColumn $singleColumn
				$firstOutput = $false
				if ($recursive) {
					foreach ($child in $entries) {
						if ($child -is [System.IO.DirectoryInfo] -and -not ($child.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
							$queue.Enqueue($child)
						}
					}
				}
			}
		}
	}
}
