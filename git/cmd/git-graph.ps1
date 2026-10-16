$gitExecutable = (Get-Command git -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
& $gitExecutable log --all --graph --oneline @args
exit $LASTEXITCODE
