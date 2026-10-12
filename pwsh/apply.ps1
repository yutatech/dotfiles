$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$File = Join-Path $ScriptDir "Microsoft.PowerShell_profile.ps1"

cp $File "$HOME\OneDrive - Sony\ドキュメント\PowerShell\"