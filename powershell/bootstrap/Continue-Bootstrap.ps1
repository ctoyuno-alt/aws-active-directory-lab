<#
.SYNOPSIS
    Bootstrap state machine dispatcher.
.DESCRIPTION
    Main drive engine for server bootstrapping. Loads current state, validates it,
    and runs a loop calling stage handlers on the corresponding role script.
    Centralizes all rebooting and stage transitions.
#>

. "$PSScriptRoot/Bootstrap-State.ps1"
. "$PSScriptRoot/common/Logging.ps1"

$state = Get-BootstrapState

if ($null -eq $state) {
    Write-BootstrapLog "No bootstrap state found. Cannot continue." -Level ERROR
    exit 1
}

Write-BootstrapLog "======================================="
Write-BootstrapLog "Starting Bootstrap State Machine Loop"
Write-BootstrapLog "Role         : $($state.Role)"
Write-BootstrapLog "Current Stage: $($state.Stage)"
Write-BootstrapLog "======================================="

# Verify current stage is valid
if ($state.Stage -notin $ValidStages) {
    Write-BootstrapLog "Invalid stage: $($state.Stage)" -Level ERROR
    throw "Invalid stage: $($state.Stage)"
}

$roleScript = "$PSScriptRoot/roles/$($state.Role).ps1"
if (-not (Test-Path $roleScript)) {
    Write-BootstrapLog "Role script not found: $roleScript" -Level ERROR
    throw "Role script not found: $roleScript"
}

$rebootPending = $false

while ($state.Stage -ne "Complete" -and -not $rebootPending) {
    Write-BootstrapLog "Dispatching stage: $($state.Stage)"
    
    $result = $null
    switch ($state.Stage) {
        "Initial" {
            $result = & $roleScript -Stage "Initial"
        }
        "DomainJoinPending" {
            $result = & $roleScript -Stage "DomainJoinPending"
        }
        "PromotionPending" {
            $result = & $roleScript -Stage "PromotionPending"
        }
        "PostPromotionPending" {
            $result = & $roleScript -Stage "PostPromotionPending"
        }
        "RoleConfigurationPending" {
            $result = & $roleScript -Stage "RoleConfigurationPending"
        }
        default {
            Write-BootstrapLog "Unhandled stage for execution: $($state.Stage)" -Level ERROR
            throw "Unhandled stage: $($state.Stage)"
        }
    }

    if ($null -eq $result -or -not $result.ContainsKey("NextStage")) {
        Write-BootstrapLog "Invalid or null result returned from role script for stage $($state.Stage)." -Level ERROR
        throw "Invalid stage execution result."
    }

    $nextStage = $result.NextStage
    $rebootRequired = [bool]$result.RebootRequired

    Write-BootstrapLog "Stage transition request: $($state.Stage) -> $nextStage (RebootRequired: $rebootRequired)"

    # Validate next stage
    if ($nextStage -notin $ValidStages) {
        Write-BootstrapLog "Invalid next stage: $nextStage" -Level ERROR
        throw "Invalid next stage: $nextStage"
    }

    # Update state
    $state.Stage = $nextStage
    Save-BootstrapState $state

    if ($rebootRequired) {
        $rebootPending = $true
        Restart-BootstrapSystem -Reason "Transition to stage $nextStage"
    } else {
        # Refresh state for next loop iteration
        $state = Get-BootstrapState
    }
}

if ($state.Stage -eq "Complete") {
    Write-BootstrapLog "Provisioning is Complete. Cleaning up scheduled task."
    
    $registerTaskScript = "$PSScriptRoot/Register-BootstrapTask.ps1"
    if (Test-Path $registerTaskScript) {
        . $registerTaskScript
        Remove-BootstrapTask
    } else {
        Write-BootstrapLog "Register-BootstrapTask.ps1 not found, cannot remove scheduled task." -Level WARNING
    }
    
    Write-BootstrapLog "Bootstrap process finished successfully."
}