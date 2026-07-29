<#
.SYNOPSIS
    Joins the local computer to an Active Directory domain.
.DESCRIPTION
    Checks if the computer is already a member of the specified domain. If not, joins the domain
    using the provided credentials (or retrieves them from AWS Parameter Store) and optionally restarts.
.PARAMETER DomainName
    The target domain name to join (e.g. corp.lab).
.PARAMETER Credential
    The domain administrator or delegated credential. If not provided, the script will attempt to
    retrieve credentials from AWS Systems Manager Parameter Store.
.PARAMETER Restart
    Switch to immediately restart the computer after successfully joining the domain.
.EXAMPLE
    .\Join-Domain.ps1 -DomainName "corp.lab" -Restart
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainName,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [switch]$Restart
)

$sysInfo = Get-CimInstance -ClassName Win32_ComputerSystem

if ($sysInfo.PartOfDomain -and ($sysInfo.Domain -ieq $DomainName)) {
    Write-Host "Computer is already joined to the domain '$DomainName'." -ForegroundColor Green
    return
}

# Resolve credential if not provided
$domainCred = $Credential
if ($null -eq $domainCred) {
    $credScript = Join-Path $PSScriptRoot "Get-DomainCredential.ps1"
    if (Test-Path $credScript) {
        Write-Host "No credential provided. Retrieving domain credentials via common script..." -ForegroundColor Yellow
        $domainCred = & $credScript
    } else {
        Write-Error "No credential provided and Get-DomainCredential.ps1 was not found in the same folder." -ErrorAction Stop
    }
}

Write-Host "Joining domain '$DomainName'..." -ForegroundColor Yellow
try {
    Add-Computer -DomainName $DomainName -Credential $domainCred -Force -ErrorAction Stop
    Write-Host "Successfully joined domain '$DomainName'." -ForegroundColor Green

    if ($Restart) {
        Write-Host "Restarting computer now..." -ForegroundColor Yellow
        Restart-Computer -Force
    } else {
        Write-Host "A system restart is required for changes to take effect." -ForegroundColor Warning
    }
} catch {
    Write-Error "Failed to join domain '$DomainName': $_"
    throw
}
