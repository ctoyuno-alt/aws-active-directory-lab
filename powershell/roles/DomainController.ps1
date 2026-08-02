<#
.SYNOPSIS
    Configures a Primary Domain Controller.
.DESCRIPTION
    Performs tasks for each state machine stage (rename, install AD DS & promote,
    reset Domain Admin password) and requests reboots and state transitions.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$DomainName = "corp.lab",

    [Parameter(Mandatory = $false)]
    [System.Security.SecureString]$SafeModeAdministratorPassword,

    [Parameter(Mandatory = $false)]
    [string]$PasswordParameter = "/ad/corp.lab/domain-admin-password",

    [Parameter(Mandatory = $false)]
    [string]$Stage
)

$Root = Split-Path $PSScriptRoot -Parent

. "$Root/common/Logging.ps1"
. "$Root/Bootstrap-State.ps1"

Write-BootstrapLog "======================================="
Write-BootstrapLog "Domain Controller Provisioning - Stage: $Stage"
Write-BootstrapLog "======================================="

try {
    switch ($Stage) {
        "Initial" {
            $state = Get-BootstrapState
            $currentName = $env:COMPUTERNAME
            if ($currentName -ine $state.Hostname) {
                Write-BootstrapLog "Renaming computer to $($state.Hostname)."
                . "$Root/common/Rename-Computer.ps1" -NewName $state.Hostname
                return @{ NextStage = "PromotionPending"; RebootRequired = $true }
            }
            return @{ NextStage = "PromotionPending"; RebootRequired = $false }
        }

        "PromotionPending" {
            #
            # Install AD DS Feature
            #
            $feature = Get-WindowsFeature -Name AD-Domain-Services
            if (-not $feature.Installed) {
                Write-BootstrapLog "Installing Active Directory Domain Services."
                . "$Root/common/Install-ADDSFeature.ps1"
                Write-BootstrapLog "AD DS feature installed."
            } else {
                Write-BootstrapLog "AD DS feature already installed."
            }

            #
            # Retrieve DSRM password
            #
            $dsrmPassword = $SafeModeAdministratorPassword
            if ($null -eq $dsrmPassword) {
                Write-BootstrapLog "DSRM password not supplied. Retrieving from Parameter Store parameter '$PasswordParameter'..."
                try {
                    Import-Module AWS.Tools.SimpleSystemsManagement -ErrorAction Stop
                    $plainPassword = (Get-SSMParameterValue -Name $PasswordParameter -WithDecryption $true).Parameters[0].Value
                    $dsrmPassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force
                    Write-BootstrapLog "Successfully retrieved password from Parameter Store."
                } catch {
                    Write-BootstrapLog "Failed to retrieve password from Parameter Store: $($_.Exception.Message)" -Level ERROR
                    throw
                }
            }

            #
            # Promote to Domain Controller
            #
            Write-BootstrapLog "Promoting server to Primary Domain Controller."
            & "$Root/dc01/Promote-Forest.ps1" -SafeModeAdministratorPassword $dsrmPassword -DomainName $DomainName
            Write-BootstrapLog "Promotion completed."

            return @{ NextStage = "PostPromotionPending"; RebootRequired = $true }
        }

        "PostPromotionPending" {
            #
            # Reset Domain Administrator Password
            #
            Write-BootstrapLog "Resetting Domain Administrator password."
            & "$Root/dc01/Reset-DomainAdministrator.ps1"
            Write-BootstrapLog "Administrator password configured."

            return @{ NextStage = "Complete"; RebootRequired = $false }
        }

        default {
            Write-BootstrapLog "Unknown or unsupported stage '$Stage' for Domain Controller." -Level ERROR
            throw "Unknown stage '$Stage'"
        }
    }
}
catch {
    Write-BootstrapLog "Domain Controller provisioning failed in stage '$Stage': $($_.Exception.Message)" -Level ERROR
    throw
}