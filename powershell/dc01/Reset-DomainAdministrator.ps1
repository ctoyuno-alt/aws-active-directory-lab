<#
.SYNOPSIS
    Resets the Active Directory Domain Administrator password and updates the AWS SSM Parameter Store.
.DESCRIPTION
    Resets the password for the specified Domain Administrator account in AD,
    and synchronizes the new password to the AWS Systems Manager Parameter Store.
.PARAMETER NewPassword
    The new password to set. If not provided, a strong 24-character random password will be generated automatically.
.PARAMETER DomainAdminUsername
    The username of the domain administrator. Defaults to 'Administrator'.
.PARAMETER PasswordParameter
    The AWS SSM Parameter Store parameter name containing the domain administrator password.
    Defaults to '/ad/corp.lab/domain-admin-password'.
.EXAMPLE
    .\Reset-DomainAdministrator.ps1 -NewPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [System.Security.SecureString]$NewPassword,

    [Parameter(Mandatory = $false)]
    [string]$DomainAdminUsername = "Administrator",

    [Parameter(Mandatory = $false)]
    [string]$PasswordParameter = "/ad/corp.lab/domain-admin-password"
)

# 1. Ensure ActiveDirectory module is available
try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    Write-Error "ActiveDirectory PowerShell module is required to run this script."
    throw
}

# 2. Determine or generate new password
$plainPassword = ""
$securePassword = $NewPassword

if ($null -eq $securePassword) {
    Write-Host "No password provided. Generating a strong 24-character random password..." -ForegroundColor Yellow
    # Fallback random string generator meeting complexity rules
    $charSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#%^&*()-_=+"
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object Byte[] 24
    $rng.GetBytes($bytes)
    $result = New-Object System.Text.StringBuilder
    foreach ($byte in $bytes) {
        $result.Append($charSet[$byte % $charSet.Length]) | Out-Null
    }
    $plainPassword = $result.ToString()
    $securePassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force
} else {
    # Extract plain text password to save to SSM Parameter Store
    $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    )
}

# 3. Reset the AD Account Password
Write-Host "Resetting Active Directory password for user '$DomainAdminUsername'..." -ForegroundColor Yellow
try {
    $adUser = Get-ADUser -Identity $DomainAdminUsername -ErrorAction Stop
    Set-ADAccountPassword -Identity $adUser -NewPassword $securePassword -Reset -ErrorAction Stop
    # Enable the account if disabled
    Enable-ADAccount -Identity $adUser -ErrorAction Stop
    Write-Host "[+] Successfully reset password in Active Directory." -ForegroundColor Green
} catch {
    Write-Error "Failed to reset password in Active Directory: $_"
    throw
}

# 4. Update the AWS SSM Parameter Store
Write-Host "Updating AWS SSM Parameter Store parameter '$PasswordParameter'..." -ForegroundColor Yellow
try {
    Import-Module AWS.Tools.SimpleSystemsManagement -ErrorAction Stop
    
    $result = Write-SSMParameter `
        -Name $PasswordParameter `
        -Value $plainPassword `
        -Type SecureString `
        -Overwrite $true `
        -ErrorAction Stop
        
    Write-Host "[+] Successfully updated SSM Parameter Store. (Version: $($result.Version))" -ForegroundColor Green
} catch {
    Write-Warning "Password was updated in AD, but failed to update SSM Parameter Store: $_"
    Write-Warning "Ensure you update SSM Parameter Store manually to keep credentials in sync."
}
