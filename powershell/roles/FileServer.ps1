<#
.SYNOPSIS
    Configures a Windows File Server.
.DESCRIPTION
    Performs tasks for each state machine stage (rename, join domain, install role and create shares)
    and returns transitions/reboot requests back to the driver engine.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Stage
)

$Root = Split-Path $PSScriptRoot -Parent

. "$Root/common/Logging.ps1"
. "$Root/Bootstrap-State.ps1"

Write-BootstrapLog "======================================="
Write-BootstrapLog "File Server Provisioning - Stage: $Stage"
Write-BootstrapLog "======================================="

try {
    switch ($Stage) {
        "Initial" {
            $state = Get-BootstrapState
            $currentName = $env:COMPUTERNAME
            if ($currentName -ine $state.Hostname) {
                Write-BootstrapLog "Renaming computer to $($state.Hostname)."
                . "$Root/common/Rename-Computer.ps1" -NewName $state.Hostname
                return @{ NextStage = "DomainJoinPending"; RebootRequired = $true }
            }
            return @{ NextStage = "DomainJoinPending"; RebootRequired = $false }
        }

        "DomainJoinPending" {
            $state = Get-BootstrapState
            Write-BootstrapLog "Joining domain $($state.Domain)."
            . "$Root/common/Join-Domain.ps1" -DomainName $state.Domain
            return @{ NextStage = "RoleConfigurationPending"; RebootRequired = $true }
        }

        "RoleConfigurationPending" {
            #
            # Install File Server Role
            #
            $feature = Get-WindowsFeature -Name FS-FileServer
            if (-not $feature.Installed) {
                Write-BootstrapLog "Installing File Server role."
                Install-WindowsFeature -Name FS-FileServer -IncludeManagementTools
                Write-BootstrapLog "File Server role installed."
            } else {
                Write-BootstrapLog "File Server role already installed."
            }

            #
            # Create Share Root
            #
            $shareRoot = "C:\Shares"
            if (-not (Test-Path $shareRoot)) {
                New-Item -ItemType Directory -Path $shareRoot -Force | Out-Null
                Write-BootstrapLog "Created share root: $shareRoot"
            } else {
                Write-BootstrapLog "Share root already exists: $shareRoot"
            }

            return @{ NextStage = "Complete"; RebootRequired = $false }
        }

        default {
            Write-BootstrapLog "Unknown or unsupported stage '$Stage' for File Server." -Level ERROR
            throw "Unknown stage '$Stage'"
        }
    }
}
catch {
    Write-BootstrapLog "File Server provisioning failed in stage '$Stage': $($_.Exception.Message)" -Level ERROR
    throw
}