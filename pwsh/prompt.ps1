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

    if (Get-Command Write-DotfilesUpdateStatus -ErrorAction SilentlyContinue) {
        Write-DotfilesUpdateStatus
    }
    Write-GitPromptStatus

    Write-Host $venv -NoNewline
    Write-Host "$userName@$computerName" -ForegroundColor Green -NoNewline
    Write-Host ':' -NoNewline
    Write-Host $currentPath -ForegroundColor Blue -NoNewline

    return "$symbol "
}
