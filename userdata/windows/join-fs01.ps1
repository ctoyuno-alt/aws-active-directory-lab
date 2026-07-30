<powershell>
<#
.SYNOPSIS
    Bootstrap script for FS01.
.DESCRIPTION
    Renames the computer to FS01 and joins it to the corp.lab domain.
#>

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($scriptDir)) {
    $scriptDir = "C:\bootstrap"
}

$renameScript = Join-Path $scriptDir "../../powershell/common/Rename-Computer.ps1"
$joinScript   = Join-Path $scriptDir "../../powershell/common/Join-Domain.ps1"

# Rename to FS01
if (Test-Path $renameScript) {
    Write-Host "Running reusable Rename-Computer script..."
    & $renameScript -NewName "FS01" -Restart
} else {
    if ($env:COMPUTERNAME -ine "FS01") {
        Rename-Computer -NewName "FS01" -Force
        Restart-Computer -Force
    }
}

# Join the domain
if (Test-Path $joinScript) {
    Write-Host "Running reusable Join-Domain script..."
    & $joinScript -DomainName "corp.lab" -Restart
} else {
    throw "Join-Domain.ps1 not found."
}
</powershell>