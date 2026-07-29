<powershell>
<#
.SYNOPSIS
    Orchestration script to bootstrap DC02.
.DESCRIPTION
    Renames the computer to DC02 and joins it to the corp.lab domain
    by invoking the reusable PowerShell automation scripts.
#>

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($scriptDir)) {
    $scriptDir = "C:\bootstrap"
}

# Resolve paths to reusable scripts
$renameScript = Join-Path $scriptDir "../../powershell/common/Rename-Computer.ps1"
$joinScript = Join-Path $scriptDir "../../powershell/common/Join-Domain.ps1"

# 1. Rename the computer to DC02 (and restart if name changes)
if (Test-Path $renameScript) {
    Write-Host "Running reusable Rename-Computer script..."
    & $renameScript -NewName "DC02" -Restart
} else {
    Write-Host "Rename script not found. Running inline..."
    if ($env:COMPUTERNAME -ine "DC02") {
        Rename-Computer -NewName "DC02" -Force
        Restart-Computer -Force
    }
}

# 2. Join the domain corp.lab
# Note: If the machine rebooted due to rename, this part will run on the next execution/boot.
if (Test-Path $joinScript) {
    Write-Host "Running reusable Join-Domain script..."
    & $joinScript -DomainName "corp.lab" -Restart
} else {
    Write-Host "Join domain script not found. Running inline..."
    $Password = ConvertTo-SecureString $env:DOMAIN_PASSWORD -AsPlainText -Force
    $Credential = New-Object PSCredential("CORP\Administrator", $Password)
    Add-Computer -DomainName "corp.lab" -Credential $Credential -Force
    Restart-Computer -Force
}
</powershell>