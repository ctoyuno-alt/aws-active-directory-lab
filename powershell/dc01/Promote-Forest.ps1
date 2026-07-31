<#
.SYNOPSIS
    Installs a new Active Directory Forest on the local computer (DC01 promotion).
.DESCRIPTION
    Promotes the system to a forest root domain controller using the provided DSRM password.
.PARAMETER SafeModeAdministratorPassword
    The Directory Services Restore Mode (DSRM) password.
.PARAMETER DomainName
    The FQDN of the root domain in the new forest (e.g. corp.lab).
.EXAMPLE
    .\Promote-Forest.ps1 -SafeModeAdministratorPassword $dsrmPassword -DomainName "corp.lab"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [System.Security.SecureString]$SafeModeAdministratorPassword,

    [Parameter(Mandatory = $false)]
    [string]$DomainName = "corp.lab"
)

# 1. Check if already a Domain Controller
$role = (Get-CimInstance -ClassName Win32_ComputerSystem).DomainRole
if ($role -eq 4 -or $role -eq 5) {
    Write-Host "This computer is already a Domain Controller. Promotion is not needed." -ForegroundColor Green
    return
}

# 2. Install AD DS Forest
Write-Host "Promoting server to a Domain Controller in a new Forest: '$DomainName'..." -ForegroundColor Yellow
try {
    # We set -NoRebootOnCompletion:$true to allow the bootstrap framework to control the reboot.
    Install-ADDSForest `
        -DomainName $DomainName `
        -SafeModeAdministratorPassword $SafeModeAdministratorPassword `
        -Force `
        -DatabasePath "C:\Windows\NTDS" `
        -LogPath "C:\Windows\NTDS" `
        -SysvolPath "C:\Windows\SYSVOL" `
        -NoRebootOnCompletion:$true `
        -ErrorAction Stop
        
    Write-Host "AD DS Forest promotion completed successfully." -ForegroundColor Green
} catch {
    Write-Error "Failed to promote server to Active Directory Forest: $_"
    throw
}
