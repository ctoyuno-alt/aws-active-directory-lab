<#
.SYNOPSIS
    Creates the 'ssm-user' Active Directory account required for SSM Session Manager on Domain Controllers.
.DESCRIPTION
    Active Directory Domain Controllers do not have a local SAM user database.
    This script provisions 'ssm-user' as an Active Directory domain user in corp.lab and adds it to
    Domain Admins so that AWS SSM Session Manager can authenticate interactive shell sessions.
.EXAMPLE
    .\Initialize-SSMUser.ps1
#>
[CmdletBinding()]
param(
    [string]$DomainAdminPasswordParameter = "/ad/corp.lab/domain-admin-password"
)

Import-Module ActiveDirectory -ErrorAction Stop
Import-Module AWS.Tools.SimpleSystemsManagement -ErrorAction SilentlyContinue

Write-Output "Checking for 'ssm-user' in Active Directory domain..."

$ssmUser = Get-ADUser -Filter "SamAccountName -eq 'ssm-user'" -ErrorAction SilentlyContinue

if ($null -ne $ssmUser) {
    Write-Output "[+] 'ssm-user' already exists in Active Directory."
    return
}

Write-Output "Creating 'ssm-user' Active Directory domain account..."

# Retrieve password from Parameter Store or generate strong random password
$plainPassword = ""
try {
    $plainPassword = (Get-SSMParameterValue -Name $DomainAdminPasswordParameter -WithDecryption $true).Parameters[0].Value
} catch {
    $plainPassword = "P@ssw0rd!" + [System.Guid]::NewGuid().ToString().Substring(0, 8)
}

$securePassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force

try {
    New-ADUser `
        -Name "ssm-user" `
        -SamAccountName "ssm-user" `
        -UserPrincipalName "ssm-user@corp.lab" `
        -AccountPassword $securePassword `
        -Enabled $true `
        -PasswordNeverExpires $true `
        -CannotChangePassword $true `
        -ErrorAction Stop

    Add-ADGroupMember -Identity "Domain Admins" -Members "ssm-user" -ErrorAction Stop
    Write-Output "[+] Successfully created 'ssm-user' in Active Directory and added to Domain Admins."
} catch {
    Write-Error "Failed to create 'ssm-user' in Active Directory: $_"
    throw
}
