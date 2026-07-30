<#
.SYNOPSIS
    Continues Windows provisioning after each reboot.
#>

# Import framework
. "$PSScriptRoot\Bootstrap-State.ps1"
. "$PSScriptRoot\Register-BootstrapTask.ps1"
. "$PSScriptRoot\..\common\Logging.ps1"
. "$PSScriptRoot\..\common\Join-Domain.ps1"

Write-BootstrapLog "Continue-Bootstrap started."

$state = Get-BootstrapState

if ($null -eq $state) {
    Write-BootstrapLog "Bootstrap state not found." -Level ERROR
    exit 1
}

Write-BootstrapLog "Current stage: $($state.Stage)"

switch ($state.Stage) {

    "RenameComplete" {

        Write-BootstrapLog "Joining domain..."

        Join-Domain `
            -DomainName $state.Domain `
            -Restart

        $state.Stage = "DomainJoined"

        Save-BootstrapState $state

        return
    }

    "DomainJoined" {

        Write-BootstrapLog "Domain join completed."

        Write-BootstrapLog "Role: $($state.Role)"

        switch ($state.Role) {

           "FileServer" {

                Write-BootstrapLog "Starting File Server role."

                & "$PSScriptRoot\..\roles\FileServer.ps1"

                Write-BootstrapLog "File Server role completed."
            }

            "ApplicationServer" {

                Write-BootstrapLog "Configuring Application Server."
            }

            "SqlServer" {

                Write-BootstrapLog "Configuring SQL Server."
            }

            "DomainController" {

                Write-BootstrapLog "Configuring Domain Controller."
            }
        }

        $state.Stage = "Completed"

        Save-BootstrapState $state

        Remove-BootstrapTask

        Write-BootstrapLog "Bootstrap completed successfully."

        return
    }

    "Completed" {

        Write-BootstrapLog "Bootstrap already completed."

        Remove-BootstrapTask

        return
    }

    default {

        Write-BootstrapLog "Unknown bootstrap stage: $($state.Stage)" -Level ERROR
    }
}