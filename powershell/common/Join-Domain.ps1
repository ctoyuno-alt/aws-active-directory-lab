<#
.SYNOPSIS
    Joins the local computer to an Active Directory domain.
.DESCRIPTION
    Checks if the computer is already a member of the specified domain. If not, joins the domain
    using the provided credentials (or retrieves them from AWS Parameter Store).
.PARAMETER DomainName
    The target domain name to join (e.g. corp.lab).
.PARAMETER Credential
    The domain administrator or delegated credential. If not provided, the script will attempt to
    retrieve credentials from AWS Systems Manager Parameter Store.
.EXAMPLE
    .\Join-Domain.ps1 -DomainName "corp.lab"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainName,

    [Parameter(Mandatory = $false)]
    [string[]]$DnsServers = @("10.10.10.10", "10.10.20.10"),

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential
)

$Root = Split-Path $PSScriptRoot -Parent

. "$Root/common/Logging.ps1"

$sysInfo = Get-CimInstance -ClassName Win32_ComputerSystem

if ($sysInfo.PartOfDomain -and ($sysInfo.Domain -ieq $DomainName)) {
    Write-BootstrapLog "Computer is already joined to the domain '$DomainName'."
    return
}

if ($DnsServers -and $DnsServers.Count -gt 0) {
    $dnsScript = "$PSScriptRoot/Set-DnsServer.ps1"
    if (Test-Path $dnsScript) {
        Write-BootstrapLog "Configuring DNS servers: $($DnsServers -join ', ')"
        & $dnsScript -DnsServers $DnsServers
    } else {
        Write-BootstrapLog "Set-DnsServer.ps1 not found, setting DNS inline..." -Level WARNING
        $adapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $DnsServers
    }
}

# Resolve credential if not provided
$domainCred = $Credential

if ($null -eq $domainCred) {
    Write-BootstrapLog "No credential provided. Retrieving domain credentials."
    $domainCred = & "$PSScriptRoot/Get-DomainCredential.ps1"
}

Write-BootstrapLog "Joining domain '$DomainName'..."
try {
    Add-Computer -DomainName $DomainName -Credential $domainCred -Force -ErrorAction Stop
    Write-BootstrapLog "Successfully joined domain '$DomainName'."
    Write-BootstrapLog "Domain join completed. System restart required."
} catch {
    Write-BootstrapLog "Failed to join domain '$DomainName': $($_.Exception.Message)" -Level ERROR
    throw
}
