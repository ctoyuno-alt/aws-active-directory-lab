<#
.SYNOPSIS
    Configures an Additional Domain Controller.
.DESCRIPTION
    Performs tasks for each state machine stage (rename, configure DNS & join domain,
    install AD DS & promote to replica DC, validate replication) and requests reboots and state transitions.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$DomainName = "corp.lab",

    [Parameter(Mandatory = $false)]
    [string]$ParentDnsServer = "10.10.10.10",

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [System.Security.SecureString]$SafeModeAdministratorPassword,

    [Parameter(Mandatory = $false)]
    [string]$Stage
)

$Root = Split-Path $PSScriptRoot -Parent

. "$Root/common/Logging.ps1"
. "$Root/bootstrap/Bootstrap-State.ps1"

Write-BootstrapLog "========================================="
Write-BootstrapLog "Additional Domain Controller Provisioning - Stage: $Stage"
Write-BootstrapLog "========================================="

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
            #
            # 1. Configure DNS to point to the primary DNS server so we can resolve the domain
            #
            Write-BootstrapLog "Configuring DNS to point to Primary Domain Controller ($ParentDnsServer)..."
            $dnsScript = "$Root/common/Set-DnsServer.ps1"
            if (Test-Path $dnsScript) {
                & $dnsScript -DnsServers @($ParentDnsServer)
            } else {
                Write-BootstrapLog "DNS script not found. Configuring DNS inline..." -Level WARNING
                $adapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
                Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @($ParentDnsServer)
            }

            #
            # 2. Ensure AD-Domain-Services feature is installed
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
            # 3. Join the Domain
            #
            $state = Get-BootstrapState
            Write-BootstrapLog "Joining domain $($state.Domain)."
            . "$Root/common/Join-Domain.ps1" -DomainName $state.Domain
            return @{ NextStage = "PromotionPending"; RebootRequired = $true }
        }

        "PromotionPending" {
            #
            # 1. Get Credentials
            #
            Write-BootstrapLog "Retrieving domain credentials."
            $domainCred = $Credential
            if ($null -eq $domainCred) {
                $credScript = "$Root/common/Get-DomainCredential.ps1"
                if (Test-Path $credScript) {
                    $domainCred = & $credScript
                } else {
                    Write-BootstrapLog "Credential script not found and no Credential parameter provided." -Level ERROR
                    throw "Credential script not found and no Credential parameter provided."
                }
            }

            #
            # 2. Determine DSRM password
            #
            Write-BootstrapLog "Determining DSRM password."
            $dsrmPassword = $SafeModeAdministratorPassword
            if ($null -eq $dsrmPassword) {
                Write-BootstrapLog "Using domain administrator password for DSRM."
                $dsrmPassword = $domainCred.Password
            }

            #
            # 3. Run promotion script
            #
            Write-BootstrapLog "Promoting to Additional Domain Controller."
            & "$Root/dc02/Promote-AdditionalDC.ps1" `
                -Credential $domainCred `
                -SafeModeAdministratorPassword $dsrmPassword `
                -DomainName $DomainName
            Write-BootstrapLog "Promotion completed."

            return @{ NextStage = "PostPromotionPending"; RebootRequired = $true }
        }

        "PostPromotionPending" {
            #
            # Validate Active Directory Replication
            #
            Write-BootstrapLog "Validating Active Directory replication."
            & "$Root/dc02/Validate-Replication.ps1"
            Write-BootstrapLog "Replication validation completed."

            return @{ NextStage = "Complete"; RebootRequired = $false }
        }

        default {
            Write-BootstrapLog "Unknown or unsupported stage '$Stage' for Additional Domain Controller." -Level ERROR
            throw "Unknown stage '$Stage'"
        }
    }
}
catch {
    Write-BootstrapLog "Additional Domain Controller provisioning failed in stage '$Stage': $($_.Exception.Message)" -Level ERROR
    throw
}