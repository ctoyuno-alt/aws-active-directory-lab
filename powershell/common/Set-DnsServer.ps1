param(
    [Parameter(Mandatory)]
    [string[]]$DnsServers
)

$adapter = Get-NetAdapter |
    Where-Object Status -eq "Up" |
    Select-Object -First 1

Write-Host "Using adapter: $($adapter.Name)"
Write-Host "Configuring DNS: $($DnsServers -join ', ')"

Set-DnsClientServerAddress `
    -InterfaceIndex $adapter.ifIndex `
    -ServerAddresses $DnsServers

Write-Host "DNS configuration complete."

Get-DnsClientServerAddress `
    -InterfaceIndex $adapter.ifIndex