<#
.SYNOPSIS
    Registers and removes the Windows Scheduled Task used to continue
    the bootstrap process after reboots.
#>

$TaskName = "BootstrapProvisioning"

function Register-BootstrapTask {

    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )

    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {

        Write-BootstrapLog "Bootstrap scheduled task already exists."

        return
    }

    Write-BootstrapLog "Registering bootstrap scheduled task."

    $Action = New-ScheduledTaskAction `
        -Execute "PowerShell.exe" `
        -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""

    $Trigger = New-ScheduledTaskTrigger -AtStartup

    $Principal = New-ScheduledTaskPrincipal `
        -UserId "SYSTEM" `
        -RunLevel Highest

    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Principal $Principal `
        -Force | Out-Null

    Write-BootstrapLog "Scheduled task created successfully."
}

function Remove-BootstrapTask {

    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {

        Unregister-ScheduledTask `
            -TaskName $TaskName `
            -Confirm:$false

        Write-BootstrapLog "Bootstrap scheduled task removed."
    }
}