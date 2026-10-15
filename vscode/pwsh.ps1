$global:DotfilesCodeExecutable = Get-Command code -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1

function Get-DotfilesVSCodeSettingsPath {
    Join-Path $env:APPDATA 'Code\User\settings.json'
}

function Test-DotfilesVSCodeConfiguration {
    if (-not $global:DotfilesCodeExecutable) { return $false }

    $settingsPath = Get-DotfilesVSCodeSettingsPath
    $dotfilesSettingsPath = Join-Path $env:DOTFILES_REPO_DIR 'vscode\settings.json'
    return Test-DotfilesHardLink -LinkPath $settingsPath -TargetPath $dotfilesSettingsPath
}

if ($global:DotfilesCodeExecutable -and -not (Test-DotfilesVSCodeConfiguration)) {
    function global:code {
        Write-Host 'VS Code settings are not configured to use the dotfiles repository.'
        $answer = Read-Host 'Run the VS Code setup script now? [y/N]'
        if ($answer -notmatch '^(y|yes)$') { return }

        $setupScript = Join-Path $env:DOTFILES_REPO_DIR 'vscode\scripts\setup_vscode.ps1'
        & $setupScript
        if (-not (Test-DotfilesVSCodeConfiguration)) {
            Write-Error 'VS Code setup did not create the expected settings hard link; code remains unavailable through this prompt.'
            return
        }

        Remove-Item Function:\code
        & $global:DotfilesCodeExecutable.Source @args
    }
}
