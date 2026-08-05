[CmdletBinding()]
param()

$Root = Split-Path $PSScriptRoot

Write-Host ""
Write-Host "Enterprise AD Lab Validation" -ForegroundColor Green
Write-Host ""

& "$PSScriptRoot\Test-ADHealth.ps1"

& "$PSScriptRoot\Test-Replication.ps1"

& "$PSScriptRoot\Test-DNS.ps1"

& "$PSScriptRoot\Test-GPO.ps1"

& "$PSScriptRoot\Test-FileServer.ps1"