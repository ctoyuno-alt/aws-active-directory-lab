<#
.SYNOPSIS
    Installs the Active Directory Domain Services (AD DS) role and administration tools.
.DESCRIPTION
    Checks if the AD DS role is already installed, and installs it if missing.
.EXAMPLE
    .\Install-ADDSFeature.ps1
#>
[CmdletBinding()]
param()

Write-Host "Checking status of AD-Domain-Services Windows Feature..." -ForegroundColor Cyan

try {
    Import-Module ServerManager -ErrorAction Stop
} catch {
    Write-Error "ServerManager module not found. This script must be run on Windows Server."
    throw
}

$feature = Get-WindowsFeature -Name AD-Domain-Services

if ($feature.Installed) {
    Write-Host "AD-Domain-Services feature is already installed." -ForegroundColor Green
} else {
    Write-Host "AD-Domain-Services feature is not installed. Installing..." -ForegroundColor Yellow
    try {
        $result = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop
        if ($result.Success) {
            Write-Host "AD-Domain-Services feature installed successfully." -ForegroundColor Green
        } else {
            Write-Error "Feature installation reported failure status."
            throw
        }
    } catch {
        Write-Error "Failed to install AD-Domain-Services feature: $_"
        throw
    }
}
