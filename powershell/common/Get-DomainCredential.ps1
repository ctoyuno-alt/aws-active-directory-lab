<#
.SYNOPSIS
Retrieves Active Directory credentials from AWS Systems Manager Parameter Store.

.DESCRIPTION
Reads the domain administrator username and password from Parameter Store
and returns a PSCredential object.

REQUIRES
- AWS Tools for PowerShell
- IAM permission:
    ssm:GetParameter
    ssm:GetParameters
#>

param(
    [string]$UsernameParameter = "/ad/corp.lab/domain-admin-username",
    [string]$PasswordParameter = "/ad/corp.lab/domain-admin-password"
)

Write-Host "Retrieving Active Directory credentials from Parameter Store..."

Import-Module AWS.Tools.SimpleSystemsManagement -ErrorAction Stop

$username = (Get-SSMParameterValue -Name $UsernameParameter).Parameters[0].Value

$password = (Get-SSMParameterValue `
    -Name $PasswordParameter `
    -WithDecryption $true).Parameters[0].Value

$securePassword = ConvertTo-SecureString `
    $password `
    -AsPlainText `
    -Force

$credential = New-Object System.Management.Automation.PSCredential (
    $username,
    $securePassword
)

return $credential