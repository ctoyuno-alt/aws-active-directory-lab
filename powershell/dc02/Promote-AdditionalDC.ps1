<#
.SYNOPSIS
    Promotes the local server to an additional Domain Controller in an existing domain (DC02 promotion).
.DESCRIPTION
    Configures DNS to point to the primary Domain Controller, ensures the AD DS feature is installed,
    retrieves credentials from AWS Parameter Store, and promotes the server.
.PARAMETER DomainName
    The FQDN of the existing domain (e.g. corp.lab).
.PARAMETER ParentDnsServer
    The IP address of the existing primary DNS / Domain Controller (e.g. 10.10.10.10).
.PARAMETER Credential
    The domain administrator credential. If not provided, the script will attempt to retrieve it from SSM.
.PARAMETER SafeModeAdministratorPassword
    The Directory Services Restore Mode (DSRM) password. If not provided, the domain admin password will be used.
.EXAMPLE
    .\Promote-AdditionalDC.ps1 -DomainName "corp.lab" -ParentDnsServer "10.10.10.10"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$DomainName = "corp.lab",

    [Parameter(Mandatory = $false)]
    [string]$ParentDnsServer = "10.10.10.10",

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [System.Security.SecureString]$SafeModeAdministratorPassword
)

# 1. Check if already a Domain Controller
$role = (Get-CimInstance -ClassName Win32_ComputerSystem).DomainRole
if ($role -eq 4 -or $role -eq 5) {
    Write-Host "This computer is already a Domain Controller." -ForegroundColor Green
    return
}

# 2. Configure DNS to point to the primary DNS server so we can resolve the domain
$dnsScript = Join-Path $PSScriptRoot "../common/Set-DnsServer.ps1"
if (Test-Path $dnsScript) {
    Write-Host "Setting DNS to point to Primary Domain Controller ($ParentDnsServer)..." -ForegroundColor Yellow
    & $dnsScript -DnsServers @($ParentDnsServer)
} else {
    Write-Host "DNS script not found. Configuring DNS inline..." -ForegroundColor Yellow
    $adapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @($ParentDnsServer)
}

# 3. Ensure AD-Domain-Services feature is installed
$addsScript = Join-Path $PSScriptRoot "../common/Install-ADDSFeature.ps1"
if (Test-Path $addsScript) {
    Write-Host "Installing ADDS feature via common script..." -ForegroundColor Yellow
    & $addsScript
} else {
    Write-Host "Common Install-ADDSFeature.ps1 script not found. Installing inline..." -ForegroundColor Yellow
    Import-Module ServerManager -ErrorAction Stop
    if (-not (Get-WindowsFeature -Name AD-Domain-Services).Installed) {
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Force -ErrorAction Stop
    }
}

# 4. Get Credentials
$domainCred = $Credential
if ($null -eq $domainCred) {
    $credScript = Join-Path $PSScriptRoot "../common/Get-DomainCredential.ps1"
    if (Test-Path $credScript) {
        Write-Host "Retrieving domain credentials via common script..." -ForegroundColor Yellow
        $domainCred = & $credScript
    } else {
        Write-Error "Credential script not found and no Credential parameter provided." -ErrorAction Stop
    }
}

# 5. Determine DSRM password
$dsrmPassword = $SafeModeAdministratorPassword
if ($null -eq $dsrmPassword) {
    Write-Host "Using domain administrator password for DSRM..." -ForegroundColor Yellow
    $dsrmPassword = $domainCred.Password
}

# 6. Promote to Domain Controller
Write-Host "Promoting server to additional Domain Controller in domain '$DomainName'..." -ForegroundColor Yellow
try {
    Install-ADDSDomainController `
        -DomainName $DomainName `
        -Credential $domainCred `
        -SafeModeAdministratorPassword $dsrmPassword `
        -Force `
        -DatabasePath "C:\Windows\NTDS" `
        -LogPath "C:\Windows\NTDS" `
        -SysvolPath "C:\Windows\SYSVOL" `
        -NoRebootOnCompletion:$false `
        -ErrorAction Stop

    Write-Host "AD DS promotion initiated. The computer will now reboot." -ForegroundColor Green
} catch {
    Write-Error "Failed to promote server to additional Domain Controller: $_"
    throw
}
