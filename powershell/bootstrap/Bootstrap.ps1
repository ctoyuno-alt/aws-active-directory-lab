<#
.SYNOPSIS
    Initializes Windows server provisioning.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Hostname,

    [Parameter(Mandatory)]
    [string]$Domain,

    [Parameter(Mandatory)]
    [string]$Role
)

# Import framework
. "$PSScriptRoot\Bootstrap-State.ps1"
. "$PSScriptRoot\Register-BootstrapTask.ps1"
. "$PSScriptRoot\..\common\Logging.ps1"
. "$PSScriptRoot\..\common\Rename-Computer.ps1"

Write-BootstrapLog "===================================================="
Write-BootstrapLog "Bootstrap Framework Started"
Write-BootstrapLog "Hostname : $Hostname"
Write-BootstrapLog "Role     : $Role"
Write-BootstrapLog "Domain   : $Domain"

# Has provisioning already started?
$state = Get-BootstrapState

if ($null -eq $state) {

    Write-BootstrapLog "Creating initial bootstrap state."

    Save-BootstrapState @{
        Hostname = $Hostname
        Domain   = $Domain
        Role     = $Role
        Stage    = "Initial"
    }
}

# Register scheduled task
Register-BootstrapTask `
    -ScriptPath "C:\bootstrap\Continue-Bootstrap.ps1"

# Rename computer if necessary
$current = $env:COMPUTERNAME

if ($current -ne $Hostname) {

    Write-BootstrapLog "Renaming computer."

    $state = Get-BootstrapState
    $state.Stage = "RenameComplete"

    Save-BootstrapState $state

    Rename-Computer `
        -NewName $Hostname `
        -Restart

    return
}

Write-BootstrapLog "Computer already renamed."

Write-BootstrapLog "Bootstrap initialization complete."