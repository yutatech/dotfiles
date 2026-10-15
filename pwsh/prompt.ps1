function prompt {
    $venv = ''
    if ($env:VIRTUAL_ENV) {
        $venv = "($(Split-Path $env:VIRTUAL_ENV -Leaf)) "
    }

    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $symbol = if ($isAdmin) { '#' } else { '$' }

    $userName = $env:USERNAME
    $computerName = $env:COMPUTERNAME
    $currentPath = (Get-Location).Path
    $homePath = [System.Environment]::GetFolderPath('UserProfile')
    if ($currentPath.StartsWith($homePath)) {
        $currentPath = '~' + $currentPath.Substring($homePath.Length)
    }

    $gitStatus = Get-GitPromptStatus
    if ($gitStatus) {
        $columns = $Host.UI.RawUI.WindowSize.Width
        $col = $columns - $gitStatus.Length + 1
        if ($col -lt 1) { $col = 1 }

        Write-Host "`e[${col}G" -NoNewline
        Write-Host "`e[1;32m$gitStatus`e[0m" -NoNewline
        Write-Host "`e[1G" -NoNewline
    }

    Write-Host $venv -NoNewline
    Write-Host "$userName@$computerName" -ForegroundColor Green -NoNewline
    Write-Host ':' -NoNewline
    Write-Host $currentPath -ForegroundColor Blue -NoNewline

    return "$symbol "
}
