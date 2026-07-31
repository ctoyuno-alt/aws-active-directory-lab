<#
.SYNOPSIS
    Initializes Windows server provisioning.
.DESCRIPTION
    Initializes the bootstrap state and registers the scheduled task to ensure
    provisioning continues on reboots. Kicks off Continue-Bootstrap.ps1 to start
    the state machine execution.
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

Write-BootstrapLog "===================================================="
Write-BootstrapLog "Bootstrap Framework Initialization Started"
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
} else {
    Write-BootstrapLog "Bootstrap state already exists. Current Stage: $($state.Stage)"
}

# Register scheduled task
Register-BootstrapTask `
    -ScriptPath "C:\bootstrap\Continue-Bootstrap.ps1"

Write-BootstrapLog "Bootstrap initialization complete. Executing state machine."

# Kick off Continue-Bootstrap.ps1
& "$PSScriptRoot\Continue-Bootstrap.ps1"