<#
.SYNOPSIS
    Installs a new Active Directory Forest on the local computer (DC01 promotion).
.DESCRIPTION
    Checks if the Active Directory Domain Services role is installed, installs it if needed,
    and promotes the system to a forest root domain controller.
.PARAMETER DomainName
    The FQDN of the root domain in the new forest (e.g. corp.lab).
.PARAMETER SafeModeAdministratorPassword
    The Directory Services Restore Mode (DSRM) password. If not provided, the script will attempt to
    retrieve it from the AWS Systems Manager Parameter Store.
.PARAMETER PasswordParameter
    The SSM parameter name containing the domain administrator password to use for DSRM.
    Defaults to '/ad/corp.lab/domain-admin-password'.
.EXAMPLE
    .\Promote-Forest.ps1 -DomainName "corp.lab"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$DomainName = "corp.lab",

    [Parameter(Mandatory = $false)]
    [System.Security.SecureString]$SafeModeAdministratorPassword,

    [Parameter(Mandatory = $false)]
    [string]$PasswordParameter = "/ad/corp.lab/domain-admin-password"
)

# 1. Check if already a Domain Controller
$role = (Get-CimInstance -ClassName Win32_ComputerSystem).DomainRole
if ($role -eq 4 -or $role -eq 5) {
    Write-Host "This computer is already a Domain Controller. Promotion is not needed." -ForegroundColor Green
    return
}

# 2. Ensure AD-Domain-Services feature is installed
$scriptPath = Join-Path $PSScriptRoot "../common/Install-ADDSFeature.ps1"
if (Test-Path $scriptPath) {
    Write-Host "Installing ADDS feature via common script..." -ForegroundColor Yellow
    & $scriptPath
} else {
    Write-Host "Common Install-ADDSFeature.ps1 script not found. Installing inline..." -ForegroundColor Yellow
    Import-Module ServerManager -ErrorAction Stop
    if (-not (Get-WindowsFeature -Name AD-Domain-Services).Installed) {
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Force -ErrorAction Stop
    }
}

# 3. Retrieve DSRM password if not provided
$dsrmPassword = $SafeModeAdministratorPassword
if ($null -eq $dsrmPassword) {
    Write-Host "DSRM password not supplied. Retrieving from Parameter Store parameter '$PasswordParameter'..." -ForegroundColor Yellow
    try {
        Import-Module AWS.Tools.SimpleSystemsManagement -ErrorAction Stop
        $plainPassword = (Get-SSMParameterValue -Name $PasswordParameter -WithDecryption $true).Parameters[0].Value
        $dsrmPassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force
        Write-Host "Successfully retrieved password from Parameter Store." -ForegroundColor Green
    } catch {
        Write-Error "Failed to retrieve password from Parameter Store: $_"
        throw
    }
}

# 4. Install AD DS Forest
Write-Host "Promoting server to a Domain Controller in a new Forest: '$DomainName'..." -ForegroundColor Yellow
try {
    # Install-ADDSForest will restart the machine upon completion by default when -Force is used.
    # We set -NoRebootOnCompletion:$false to allow it to reboot, making promotion fully automated.
    Install-ADDSForest `
        -DomainName $DomainName `
        -SafeModeAdministratorPassword $dsrmPassword `
        -Force `
        -DatabasePath "C:\Windows\NTDS" `
        -LogPath "C:\Windows\NTDS" `
        -SysvolPath "C:\Windows\SYSVOL" `
        -NoRebootOnCompletion:$false `
        -ErrorAction Stop
        
    Write-Host "AD DS Forest promotion initiated. The computer will now reboot." -ForegroundColor Green
} catch {
    Write-Error "Failed to promote server to Active Directory Forest: $_"
    throw
}
