<#
.SYNOPSIS
    Manages bootstrap provisioning state.
#>

$BootstrapDirectory = "C:\ProgramData\Bootstrap"
$BootstrapStateFile = Join-Path $BootstrapDirectory "state.json"

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