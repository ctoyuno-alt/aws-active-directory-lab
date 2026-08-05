[CmdletBinding()]
param()

Write-Host ""
Write-Host "===== GPO =====" -ForegroundColor Cyan

Write-Host "`nDomain Group Policies:" -ForegroundColor Yellow
if (Get-Module -ListAvailable GroupPolicy) {
    Import-Module GroupPolicy
    Get-GPO -All | Select-Object DisplayName, Status, GpoStatus, CreationTime | Format-Table -AutoSize
}

Write-Host "`nApplied Computer Group Policies:" -ForegroundColor Yellow
gpresult /scope computer /r