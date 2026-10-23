
function touch {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Path
    )

    foreach ($p in $Path) {
        if (Test-Path $p) {
            (Get-Item $p).LastWriteTime = Get-Date
        }
        else {
            New-Item -ItemType File -Path $p | Out-Null
        }
    }
}