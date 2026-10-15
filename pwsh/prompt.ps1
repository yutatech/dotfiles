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

    Write-GitPromptStatus

    Write-Host $venv -NoNewline
    Write-Host "$userName@$computerName" -ForegroundColor Green -NoNewline
    Write-Host ':' -NoNewline
    Write-Host $currentPath -ForegroundColor Blue -NoNewline

    return "$symbol "
}
