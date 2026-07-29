<#
.SYNOPSIS
    Renames the local computer to a specified hostname.
.DESCRIPTION
    Checks the current computer name, compares it to the target name,
    renames the computer if they differ, and optionally restarts the system.
.PARAMETER NewName
    The target hostname for the local computer.
.PARAMETER Restart
    Switch to immediately restart the computer after renaming.
.EXAMPLE
    .\Rename-Computer.ps1 -NewName "DC01" -Restart
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$NewName,

    [Parameter(Mandatory = $false)]
    [switch]$Restart
)

$currentName = $env:COMPUTERNAME

if ($currentName -ieq $NewName) {
    Write-Host "Computer name is already '$NewName'. No rename required." -ForegroundColor Green
    return
}

Write-Host "Renaming computer from '$currentName' to '$NewName'..." -ForegroundColor Yellow
try {
    Rename-Computer -NewName $NewName -Force -ErrorAction Stop
    Write-Host "Computer successfully renamed to '$NewName'." -ForegroundColor Green
    
    if ($Restart) {
        Write-Host "Restarting computer now..." -ForegroundColor Yellow
        Restart-Computer -Force
    } else {
        Write-Host "A system restart is required for changes to take effect." -ForegroundColor Warning
    }
} catch {
    Write-Error "Failed to rename computer: $_"
    throw
}
