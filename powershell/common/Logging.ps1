<#
.SYNOPSIS
    Common logging functions for the bootstrap framework.
#>

$BootstrapDirectory = "C:\ProgramData\Bootstrap"
$LogFile = Join-Path $BootstrapDirectory "bootstrap.log"

function Initialize-Log {

    if (!(Test-Path $BootstrapDirectory)) {
        New-Item `
            -ItemType Directory `
            -Path $BootstrapDirectory `
            -Force | Out-Null
    }

    if (!(Test-Path $LogFile)) {
        New-Item `
            -ItemType File `
            -Path $LogFile `
            -Force | Out-Null
    }
}

function Write-BootstrapLog {

    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level = "INFO"
    )

    Initialize-Log

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $entry = "[{0}] [{1}] {2}" -f $timestamp, $Level, $Message

    Add-Content `
        -Path $LogFile `
        -Value $entry

    switch ($Level) {

        "INFO"  { Write-Host $entry -ForegroundColor Green }

        "WARN"  { Write-Host $entry -ForegroundColor Yellow }

        "ERROR" { Write-Host $entry -ForegroundColor Red }
    }
}