[CmdletBinding()]
param()

Import-Module ActiveDirectory

Write-Host ""
Write-Host "===== Active Directory Health =====" -ForegroundColor Cyan

$Domain = Get-ADDomain

Write-Host "Domain      : $($Domain.DNSRoot)"
Write-Host "NetBIOS     : $($Domain.NetBIOSName)"
Write-Host "Forest      : $($Domain.Forest)"
Write-Host "PDC Emulator: $($Domain.PDCEmulator)"
Write-Host "RID Master  : $($Domain.RIDMaster)"
Write-Host "Infra Master: $($Domain.InfrastructureMaster)"

Write-Host ""
Write-Host "Domain Controllers"

Get-ADDomainController -Filter * |
Select-Object `
Hostname,
IPv4Address,
Site,
IsGlobalCatalog |
Format-Table -AutoSize