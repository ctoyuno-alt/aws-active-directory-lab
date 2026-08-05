[CmdletBinding()]
param()

Write-Host ""
Write-Host "===== DNS =====" -ForegroundColor Cyan

Resolve-DnsName corp.lab

Resolve-DnsName dc01.corp.lab

Resolve-DnsName dc02.corp.lab

Resolve-DnsName fs01.corp.lab