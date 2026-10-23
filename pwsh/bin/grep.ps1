function grep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Pattern,

        [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
        [string[]]$Path,

        [Alias('i')]
        [switch]$IgnoreCase,

        [Alias('v')]
        [switch]$InvertMatch,

        [Alias('n')]
        [switch]$LineNumber,

        [Alias('r')]
        [switch]$Recurse,

        [Alias('l')]
        [switch]$FilesWithMatches,

        [Alias('c')]
        [switch]$Count,

        [Alias('w')]
        [switch]$WholeWord,

        [Alias('x')]
        [switch]$Exact,

        [Parameter(ValueFromPipeline = $true)]
        [AllowNull()]
        [object]$InputObject
    )

    begin {
        $pipelineLines = [System.Collections.Generic.List[string]]::new()
        $regexOptions = [System.Text.RegularExpressions.RegexOptions]::None
        if ($IgnoreCase) {
            $regexOptions = $regexOptions -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        }

        $regexPattern = $Pattern
        if ($Exact) {
            $regexPattern = "^(?:$regexPattern)$"
        }
        elseif ($WholeWord) {
            $regexPattern = "(?<![\p{L}\p{N}_])(?:$regexPattern)(?![\p{L}\p{N}_])"
        }
        $regex = [System.Text.RegularExpressions.Regex]::new($regexPattern, $regexOptions)
    }

    process {
        if ($null -eq $InputObject) {
            $pipelineLines.Add('')
        }
        else {
            $pipelineLines.Add($InputObject.ToString())
        }
    }

    end {
        $sources = [System.Collections.Generic.List[object]]::new()

        if ($Path.Count -gt 0) {
            foreach ($target in $Path) {
                foreach ($item in (Get-Item -Path $target -ErrorAction Stop)) {
                    if ($item -is [System.IO.DirectoryInfo]) {
                        if (-not $Recurse) {
                            throw "grep: '$target' is a directory; use -r to search recursively."
                        }
                        foreach ($file in (Get-ChildItem -LiteralPath $item.FullName -File -Recurse -Force -ErrorAction Stop)) {
                            $sources.Add([pscustomobject]@{ Name = $file.FullName; File = $file })
                        }
                    }
                    else {
                        $sources.Add([pscustomobject]@{ Name = $item.FullName; File = $item })
                    }
                }
            }
        }
        elseif ($pipelineLines.Count -gt 0) {
            $sources.Add([pscustomobject]@{ Name = $null; Lines = $pipelineLines })
        }
        else {
            throw 'grep: provide one or more files or pipe input to search.'
        }

        $showSource = $sources.Count -gt 1
        foreach ($source in $sources) {
            $matchCount = 0
            $lineNumberValue = 0
            $reader = $null

            try {
                if ($null -ne $source.File) {
                    $reader = [System.IO.StreamReader]::new($source.File.FullName)
                    while (($line = $reader.ReadLine()) -ne $null) {
                        $lineNumberValue++
                        $isMatch = $regex.IsMatch($line)
                        if ($isMatch -ne $InvertMatch) {
                            $matchCount++
                            if ($FilesWithMatches) {
                                break
                            }
                            if (-not $Count) {
                                $prefix = ''
                                if ($showSource) {
                                    $prefix += "$($source.Name):"
                                }
                                if ($LineNumber) {
                                    $prefix += "${lineNumberValue}:"
                                }
                                Write-Output "$prefix$line"
                            }
                        }
                    }
                }
                else {
                    foreach ($line in $source.Lines) {
                        $lineNumberValue++
                        $isMatch = $regex.IsMatch($line)
                        if ($isMatch -ne $InvertMatch) {
                            $matchCount++
                            if ($FilesWithMatches) {
                                break
                            }
                            if (-not $Count) {
                                $prefix = ''
                                if ($LineNumber) {
                                    $prefix = "${lineNumberValue}:"
                                }
                                Write-Output "$prefix$line"
                            }
                        }
                    }
                }

                if ($FilesWithMatches -and $matchCount -gt 0) {
                    Write-Output $source.Name
                }
                elseif ($Count) {
                    if ($showSource) {
                        Write-Output "$($source.Name):$matchCount"
                    }
                    else {
                        Write-Output $matchCount
                    }
                }
            }
            finally {
                if ($null -ne $reader) {
                    $reader.Dispose()
                }
            }
        }
    }
}