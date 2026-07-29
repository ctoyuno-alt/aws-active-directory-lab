<powershell>
# Bootstrap script for DC01
# Renames the computer to DC01

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($scriptDir)) {
    $scriptDir = "C:\bootstrap"
}

$renameScript = Join-Path $scriptDir "../../powershell/common/Rename-Computer.ps1"

if (Test-Path $renameScript) {
    Write-Host "Running reusable Rename-Computer script..."
    & $renameScript -NewName "DC01" -Restart
} else {
    Write-Host "Rename script not found. Running inline..."
    if ($env:COMPUTERNAME -ine "DC01") {
        Rename-Computer -NewName "DC01" -Force
        Restart-Computer -Force
    }
}
</powershell>