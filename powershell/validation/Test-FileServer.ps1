[CmdletBinding()]
param()

Write-Host ""
Write-Host "===== File Shares =====" -ForegroundColor Cyan

Get-SmbShare |
Select-Object Name,Path

Write-Host ""

Get-SmbShareAccess -Name IT

Write-Host ""

icacls C:\Shares\IT