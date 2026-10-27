function ConvertFrom-DuBlockSize {
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
	throw "du: invalid block size '$Value'."
}

function Format-DuSize {
	param([double]$Bytes, [double]$Unit, [bool]$Exact)

	if ($Exact) { return [string][math]::Floor($Bytes) }
	return [string][math]::Ceiling($Bytes / $Unit)
}

function Format-DuHumanSize {
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

function du {
	$ArgumentList = @($args)

	$unit = 1024.0
	$humanMode = $null
	$exactBytes = $false
	$all = $false
	$summarize = $false
	$showTotal = $false
	$separateDirectories = $false
	$oneFileSystem = $false
	$maxDepth = [int]::MaxValue
	$excludePatterns = [System.Collections.Generic.List[string]]::new()
	$paths = [System.Collections.Generic.List[string]]::new()

	for ($index = 0; $index -lt $ArgumentList.Count; $index++) {
		$argument = $ArgumentList[$index]
		if ($argument -eq '--') {
			for ($index++; $index -lt $ArgumentList.Count; $index++) { $paths.Add($ArgumentList[$index]) }
			break
		}
		if ($argument -in @('--help', '-help')) {
			Write-Output @(
				'使い方: du [オプション]... [ファイル]...'
				'ファイルやディレクトリの使用量を再帰的に集計します。'
				'ファイルを指定しない場合は、カレントディレクトリを集計します。'
				'既定では 1024 バイト単位で表示し、ファイルの論理サイズを使用します。'
				''
				'オプション:'
				'  -a, --all                 ファイルとディレクトリの両方を表示します。'
				'  -b, --bytes               バイト単位で正確なサイズを表示します。'
				'  -B SIZE, --block-size=SIZE SIZE バイト単位で表示します。'
				'  -c, --total               指定した対象の合計行を追加します。'
				'  -d N, --max-depth=N       深さ N まで表示します。集計は全階層を対象にします。'
				'  -h, --human-readable      1024 を基準に読みやすい単位で表示します。'
				'  -H, --si                  1000 を基準に読みやすい単位で表示します。'
				'  -k                        1024 バイト単位で表示します（既定値）。'
				'  -m                        1 MiB 単位で表示します。'
				'  -s, --summarize           各指定対象の合計だけを表示します。'
				'  -S, --separate-dirs       子ディレクトリのサイズを親の合計に含めません。'
				'  -x, --one-file-system     別ボリュームにあるディレクトリを辿りません。'
				'      --exclude=PATTERN     名前が PATTERN に一致する項目を除外します。'
				'      --apparent-size       論理サイズを使用します（既定値と同じです）。'
				'      --help                このヘルプを表示します。'
				'      --version             バージョンを表示します。'
				''
				'SIZE は整数で、K、M、G、T、P（1024 の累乗）を末尾に付けられます。'
				'PATTERN は項目名に対する PowerShell 形式のワイルドカードです。'
				'ディレクトリのシンボリックリンクやジャンクションは辿りません。'
				'GNU Coreutils の全オプションとの互換性はありません。'
			)
			return
		}
		if ($argument -eq '--version') { Write-Output 'du (PowerShell dotfiles) 1.0'; return }
		if ($argument -cin @('-h', '--human-readable')) { $humanMode = $false; $exactBytes = $false; continue }
		if ($argument -cin @('-H', '--si')) { $humanMode = $true; $exactBytes = $false; continue }
		if ($argument -cin @('-b', '--bytes', '--apparent-size')) {
			if ($argument -cne '--apparent-size') { $exactBytes = $true; $unit = 1 }
			continue
		}
		if ($argument -cin @('-a', '--all')) { $all = $true; continue }
		if ($argument -cin @('-s', '--summarize')) { $summarize = $true; continue }
		if ($argument -cin @('-c', '--total')) { $showTotal = $true; continue }
		if ($argument -cin @('-S', '--separate-dirs')) { $separateDirectories = $true; continue }
		if ($argument -cin @('-x', '--one-file-system')) { $oneFileSystem = $true; continue }
		if ($argument -match '^--exclude=(.*)$') { $excludePatterns.Add($Matches[1]); continue }
		if ($argument -match '^--max-depth=(\d+)$') { $maxDepth = [int]$Matches[1]; continue }
		if ($argument -match '^--block-size=(.+)$') { $unit = ConvertFrom-DuBlockSize $Matches[1]; $exactBytes = $false; continue }
		if ($argument -cin @('-B', '--block-size', '-d', '--max-depth', '--exclude')) {
			if (++$index -ge $ArgumentList.Count) { throw "du: option '$argument' requires an argument." }
			$value = $ArgumentList[$index]
			switch -CaseSensitive ($argument) {
				{ $_ -in @('-B', '--block-size') } { $unit = ConvertFrom-DuBlockSize $value; $exactBytes = $false }
				{ $_ -in @('-d', '--max-depth') } {
					if ($value -notmatch '^\d+$') { throw "du: invalid maximum depth '$value'." }
					$maxDepth = [int]$value
				}
				'--exclude' { $excludePatterns.Add($value) }
			}
			continue
		}
		if ($argument -match '^-[^-].*$') {
			$letters = $argument.Substring(1)
			for ($letterIndex = 0; $letterIndex -lt $letters.Length; $letterIndex++) {
				$option = $letters[$letterIndex]
				if ($option -cin @('B', 'd')) {
					$value = $letters.Substring($letterIndex + 1)
					if (-not $value) {
						if (++$index -ge $ArgumentList.Count) { throw "du: option '-$option' requires an argument." }
						$value = $ArgumentList[$index]
					}
					if ($option -ceq 'B') { $unit = ConvertFrom-DuBlockSize $value; $exactBytes = $false }
					else {
						if ($value -notmatch '^\d+$') { throw "du: invalid maximum depth '$value'." }
						$maxDepth = [int]$value
					}
					break
				}
				switch -CaseSensitive ($option) {
					'a' { $all = $true }
					'b' { $exactBytes = $true; $unit = 1; $humanMode = $null }
					'h' { $humanMode = $false }
					'H' { $humanMode = $true }
					'k' { $unit = 1024.0; $exactBytes = $false; $humanMode = $null }
					'm' { $unit = 1MB; $exactBytes = $false; $humanMode = $null }
					's' { $summarize = $true }
					'S' { $separateDirectories = $true }
					'x' { $oneFileSystem = $true }
					default { throw "du: unsupported option '-$option'." }
				}
			}
			continue
		}
		if ($argument.StartsWith('-')) { throw "du: unsupported option '$argument'." }
		$paths.Add($argument)
	}

	if ($paths.Count -eq 0) { $paths.Add('.') }
	$results = [System.Collections.Generic.List[object]]::new()
	$topLevelTotal = 0.0

	foreach ($inputPath in $paths) {
		try { $rootItem = Get-Item -LiteralPath $inputPath -Force -ErrorAction Stop }
		catch { throw "du: cannot access '$inputPath': $($_.Exception.Message)" }
		if ($rootItem.PSProvider.Name -ne 'FileSystem') { throw "du: '$inputPath' is not a filesystem path." }
		$rootPath = $rootItem.FullName
		$volumeRoot = [System.IO.Path]::GetPathRoot($rootPath)

		if (-not $rootItem.PSIsContainer) {
			$size = [double]$rootItem.Length
			$topLevelTotal += $size
			$results.Add([pscustomobject]@{ Bytes = $size; Path = $rootPath; Depth = 0; IsDirectory = $false })
			continue
		}

		$sizes = @{}
		$directories = [System.Collections.Generic.List[object]]::new()
		$stack = [System.Collections.Generic.Stack[object]]::new()
		$stack.Push([pscustomobject]@{ Path = $rootPath; Depth = 0; Visited = $false })
		while ($stack.Count -gt 0) {
			$entry = $stack.Pop()
			if (-not $entry.Visited) {
				$directories.Add([pscustomobject]@{ Path = $entry.Path; Depth = $entry.Depth })
				$stack.Push([pscustomobject]@{ Path = $entry.Path; Depth = $entry.Depth; Visited = $true })
				try { $children = @(Get-ChildItem -LiteralPath $entry.Path -Force -ErrorAction Stop) }
				catch { throw "du: cannot read '$($entry.Path)': $($_.Exception.Message)" }
				foreach ($child in $children) {
					if ($excludePatterns | Where-Object { $child.Name -like $_ }) { continue }
					if ($child.PSIsContainer) {
						if (($child.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
						if ($oneFileSystem -and [System.IO.Path]::GetPathRoot($child.FullName) -ne $volumeRoot) { continue }
						$stack.Push([pscustomobject]@{ Path = $child.FullName; Depth = $entry.Depth + 1; Visited = $false })
					}
					else {
						$fileSize = [double]$child.Length
						$sizes[$entry.Path] = [double]$sizes[$entry.Path] + $fileSize
						if ($all -and -not $summarize) { $results.Add([pscustomobject]@{ Bytes = $fileSize; Path = $child.FullName; Depth = $entry.Depth + 1; IsDirectory = $false }) }
					}
				}
			}
			else {
				$size = [double]$sizes[$entry.Path]
				foreach ($childDirectory in $directories | Where-Object { [System.IO.Path]::GetDirectoryName($_.Path) -eq $entry.Path }) {
					if ($childDirectory.Path -ne $entry.Path) {
						if (-not $separateDirectories) { $size += [double]$sizes[$childDirectory.Path] }
					}
				}
				$sizes[$entry.Path] = $size
				if ($entry.Depth -le $maxDepth -and (-not $summarize -or $entry.Depth -eq 0)) {
					$results.Add([pscustomobject]@{ Bytes = $size; Path = $entry.Path; Depth = $entry.Depth; IsDirectory = $true })
				}
			}
		}
		$rootSize = [double]$sizes[$rootPath]
		$topLevelTotal += $rootSize
		if ($summarize) {
			$results = [System.Collections.Generic.List[object]]::new(@($results | Where-Object { $_.Path -ne $rootPath }))
			$results.Add([pscustomobject]@{ Bytes = $rootSize; Path = $rootPath; Depth = 0; IsDirectory = $true })
		}
	}

	foreach ($result in $results | Sort-Object -Property @{ Expression = 'Depth'; Descending = $true }, Path) {
		if ($humanMode -ne $null) { $sizeText = Format-DuHumanSize $result.Bytes $humanMode }
		else { $sizeText = Format-DuSize $result.Bytes $unit $exactBytes }
		Write-Output ("{0,10} {1}" -f $sizeText, $result.Path)
	}
	if ($showTotal) {
		if ($humanMode -ne $null) { $totalText = Format-DuHumanSize $topLevelTotal $humanMode }
		else { $totalText = Format-DuSize $topLevelTotal $unit $exactBytes }
		Write-Output ("{0,10} total" -f $totalText)
	}
}

Register-ArgumentCompleter -CommandName du -ScriptBlock {
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
	if ($previous -in @('-d', '--max-depth')) {
		foreach ($depth in @('0', '1', '2', '3')) {
			if ($depth.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase)) {
				[System.Management.Automation.CompletionResult]::new($depth, $depth, 'ParameterValue', "Maximum depth $depth")
			}
		}
		return
	}
	if ($wordToComplete.StartsWith('-')) {
		foreach ($option in @('-a', '--all', '-b', '--bytes', '-B', '--block-size', '-c', '--total', '-d', '--max-depth', '-h', '--human-readable', '-H', '--si', '-k', '-m', '-s', '--summarize', '-S', '--separate-dirs', '-x', '--one-file-system', '--exclude', '--apparent-size', '--help')) {
			if ($option.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase)) {
				[System.Management.Automation.CompletionResult]::new($option, $option, 'ParameterName', "du option $option")
			}
		}
		return
	}

	$typedPath = $wordToComplete.Trim("'`"")
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
