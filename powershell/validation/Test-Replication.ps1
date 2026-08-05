[CmdletBinding()]
param()

Write-Host ""
Write-Host "===== Replication =====" -ForegroundColor Cyan

repadmin /replsummary

Write-Host ""

repadmin /showrepl