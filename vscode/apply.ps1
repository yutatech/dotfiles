$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$File = Join-Path $ScriptDir "settings.json"

cp $File $HOME/AppData/Roaming/Code/User/settings.json