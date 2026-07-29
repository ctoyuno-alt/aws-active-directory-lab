<#
.SYNOPSIS
    Tests the health of the Active Directory services on the local Domain Controller.
.DESCRIPTION
    Checks essential Windows services, verifies Active Directory modules are loaded,
    and runs diagnostic tests (DCDiag) to ensure domain controller health.
.OUTPUTS
    PSCustomObject representing the health status of various components.
.EXAMPLE
    .\Test-ADHealth.ps1
#>
[CmdletBinding()]
param()

Write-Host "Starting Active Directory Health Check..." -ForegroundColor Cyan

$services = @("NTDS", "DNS", "Kdc", "ADWS", "DFSR")
$healthResults = [ordered]@{
    ComputerName  = $env:COMPUTERNAME
    Timestamp     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    OverallHealth = "Pass"
}

# 1. Check Services
Write-Host "`n1. Checking Essential AD Services..." -ForegroundColor Yellow
$serviceStatuses = @()
foreach ($svcName in $services) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($null -eq $svc) {
        Write-Host "[-] Service '$svcName' is NOT installed." -ForegroundColor Red
        $healthResults.OverallHealth = "Fail"
        $serviceStatuses += [PSCustomObject]@{ Service = $svcName; Status = "Not Installed"; Healthy = $false }
    } elseif ($svc.Status -ne "Running") {
        Write-Host "[-] Service '$svcName' is installed but currently $($svc.Status)." -ForegroundColor Red
        $healthResults.OverallHealth = "Fail"
        $serviceStatuses += [PSCustomObject]@{ Service = $svcName; Status = $svc.Status; Healthy = $false }
    } else {
        Write-Host "[+] Service '$svcName' is Running." -ForegroundColor Green
        $serviceStatuses += [PSCustomObject]@{ Service = $svcName; Status = "Running"; Healthy = $true }
    }
}
$healthResults.Services = $serviceStatuses

# 2. Check if Active Directory Module is available and query domain
Write-Host "`n2. Checking Active Directory Module & Domain Status..." -ForegroundColor Yellow
try {
    Import-Module ActiveDirectory -ErrorAction Stop
    $domain = Get-ADDomain -ErrorAction Stop
    Write-Host "[+] Active Directory Module loaded successfully." -ForegroundColor Green
    Write-Host "[+] Current Domain: $($domain.DNSRoot)" -ForegroundColor Green
    $healthResults.ADModuleLoaded = $true
    $healthResults.DomainName = $domain.DNSRoot
} catch {
    Write-Host "[-] Active Directory module could not be loaded or domain is unreachable: $_" -ForegroundColor Red
    $healthResults.ADModuleLoaded = $false
    $healthResults.OverallHealth = "Fail"
}

# 3. Run basic DCDiag check
Write-Host "`n3. Running DCDiag Diagnostics..." -ForegroundColor Yellow
try {
    $dcDiagServices = dcdiag.exe /test:Services /q 2>&1
    $dcDiagReplication = dcdiag.exe /test:Replications /q 2>&1
    
    if ([string]::IsNullOrEmpty($dcDiagServices)) {
        Write-Host "[+] DCDiag Services diagnostic: Pass (No errors)" -ForegroundColor Green
        $healthResults.DCDiagServices = "Pass"
    } else {
        Write-Host "[-] DCDiag Services diagnostic encountered errors:" -ForegroundColor Red
        Write-Host $dcDiagServices -ForegroundColor DarkRed
        $healthResults.DCDiagServices = "Fail"
        $healthResults.OverallHealth = "Fail"
    }

    if ([string]::IsNullOrEmpty($dcDiagReplication)) {
        Write-Host "[+] DCDiag Replications diagnostic: Pass (No errors)" -ForegroundColor Green
        $healthResults.DCDiagReplications = "Pass"
    } else {
        Write-Host "[-] DCDiag Replications diagnostic encountered errors:" -ForegroundColor Red
        Write-Host $dcDiagReplication -ForegroundColor DarkRed
        $healthResults.DCDiagReplications = "Fail"
        $healthResults.OverallHealth = "Fail"
    }
} catch {
    Write-Host "[-] Failed to execute dcdiag utility: $_" -ForegroundColor Red
    $healthResults.DCDiagServices = "Error"
    $healthResults.DCDiagReplications = "Error"
}

# Output Summary Object
Write-Host "`n--- Health Check Summary ---" -ForegroundColor Cyan
if ($healthResults.OverallHealth -eq "Pass") {
    Write-Host "Overall AD Health: PASS" -ForegroundColor Green
} else {
    Write-Host "Overall AD Health: FAIL" -ForegroundColor Red
}

return [PSCustomObject]$healthResults
