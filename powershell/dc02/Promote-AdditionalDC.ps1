<#
.SYNOPSIS
    Promotes the local server to an additional Domain Controller in an existing domain (DC02 promotion).
.DESCRIPTION
    Promotes the server using the provided domain credentials and DSRM password.
.PARAMETER Credential
    The domain administrator credential.
.PARAMETER SafeModeAdministratorPassword
    The Directory Services Restore Mode (DSRM) password.
.PARAMETER DomainName
    The FQDN of the existing domain (e.g. corp.lab).
.EXAMPLE
    .\Promote-AdditionalDC.ps1 -Credential $cred -SafeModeAdministratorPassword $dsrmPassword -DomainName "corp.lab"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $true)]
    [System.Security.SecureString]$SafeModeAdministratorPassword,

    [Parameter(Mandatory = $false)]
    [string]$DomainName = "corp.lab"
)

# 1. Check if already a Domain Controller
$role = (Get-CimInstance -ClassName Win32_ComputerSystem).DomainRole
if ($role -eq 4 -or $role -eq 5) {
    Write-Host "This computer is already a Domain Controller." -ForegroundColor Green
    return
}

# 2. Promote to Domain Controller
Write-Host "Promoting server to additional Domain Controller in domain '$DomainName'..." -ForegroundColor Yellow
try {
    # We set -NoRebootOnCompletion:$true to allow the bootstrap framework to control the reboot.
    Install-ADDSDomainController `
        -DomainName $DomainName `
        -Credential $Credential `
        -SafeModeAdministratorPassword $SafeModeAdministratorPassword `
        -Force `
        -DatabasePath "C:\Windows\NTDS" `
        -LogPath "C:\Windows\NTDS" `
        -SysvolPath "C:\Windows\SYSVOL" `
        -NoRebootOnCompletion:$true `
        -ErrorAction Stop

    Write-Host "AD DS promotion completed successfully." -ForegroundColor Green
} catch {
    Write-Error "Failed to promote server to additional Domain Controller: $_"
    throw
}
