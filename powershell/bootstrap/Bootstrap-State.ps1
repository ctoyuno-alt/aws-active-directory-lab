<#
.SYNOPSIS
    Manages bootstrap provisioning state.
#>

$BootstrapDirectory = "C:\ProgramData\Bootstrap"
$BootstrapStateFile = Join-Path $BootstrapDirectory "state.json"

$ValidStages = @(
    "Initial",
    "DomainJoinPending",
    "PromotionPending",
    "PostPromotionPending",
    "RoleConfigurationPending",
    "Complete"
)

function Initialize-BootstrapState {

    if (!(Test-Path $BootstrapDirectory)) {
        New-Item `
            -ItemType Directory `
            -Path $BootstrapDirectory `
            -Force | Out-Null
    }
}

function Save-BootstrapState {

    param(
        [hashtable]$State
    )

    Initialize-BootstrapState

    $State |
        ConvertTo-Json -Depth 10 |
        Set-Content $BootstrapStateFile
}

function Get-BootstrapState {

    Initialize-BootstrapState

    if (!(Test-Path $BootstrapStateFile)) {
        return $null
    }

    Get-Content $BootstrapStateFile -Raw |
        ConvertFrom-Json
}

function Remove-BootstrapState {

    if (Test-Path $BootstrapStateFile) {
        Remove-Item $BootstrapStateFile -Force
    }
}

function Restart-BootstrapSystem {
    param(
        [string]$Reason = "Bootstrap request"
    )

    if (Get-Command Write-BootstrapLog -ErrorAction SilentlyContinue) {
        Write-BootstrapLog "System reboot initiated by bootstrap framework. Reason: $Reason"
    } else {
        Write-Host "System reboot initiated by bootstrap framework. Reason: $Reason" -ForegroundColor Yellow
    }

    Restart-Computer -Force
}