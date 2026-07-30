<#
.SYNOPSIS
    Configures a Windows File Server.
#>

[CmdletBinding()]
param()

. "$PSScriptRoot\..\common\Logging.ps1"

Write-BootstrapLog "Starting File Server configuration."

# Install File Server role
Install-WindowsFeature `
    -Name FS-FileServer `
    -IncludeManagementTools

Write-BootstrapLog "File Server role installed."

# Create data directory
$shareRoot = "C:\Shares"

if (!(Test-Path $shareRoot)) {

    New-Item `
        -ItemType Directory `
        -Path $shareRoot `
        -Force | Out-Null

    Write-BootstrapLog "Created $shareRoot"
}

Write-BootstrapLog "File Server configuration completed."