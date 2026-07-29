<#
.SYNOPSIS
    Validates Active Directory replication status on the local Domain Controller (DC02).
.DESCRIPTION
    Checks AD replication status and failures using ActiveDirectory cmdlets and repadmin.exe.
.OUTPUTS
    PSCustomObject containing replication partner status and failures.
.EXAMPLE
    .\Validate-Replication.ps1
#>
[CmdletBinding()]
param()

Write-Host "Validating Active Directory Replication..." -ForegroundColor Cyan

# 1. Ensure AD DS module is loaded
try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    Write-Error "ActiveDirectory PowerShell module is required to run this script."
    throw
}

$replicationResults = [ordered]@{
    ComputerName  = $env:COMPUTERNAME
    Timestamp     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Status        = "Healthy"
}

# 2. Check replication failures using Get-ADReplicationFailure
Write-Host "`n1. Checking Replication Failures (Get-ADReplicationFailure)..." -ForegroundColor Yellow
try {
    $failures = Get-ADReplicationFailure -Target $env:COMPUTERNAME -ErrorAction SilentlyContinue
    if ($null -eq $failures -or $failures.Count -eq 0) {
        Write-Host "[+] No AD replication failures detected." -ForegroundColor Green
        $replicationResults.Failures = 0
    } else {
        Write-Host "[-] Detected $($failures.Count) replication failure(s):" -ForegroundColor Red
        foreach ($failure in $failures) {
            Write-Host "    - Partner: $($failure.Partner)" -ForegroundColor DarkRed
            Write-Host "      Failure Count: $($failure.FailureCount)" -ForegroundColor DarkRed
            Write-Host "      First Failure: $($failure.FirstFailureTime)" -ForegroundColor DarkRed
            Write-Host "      Last Error: $($failure.LastErrorMessage)" -ForegroundColor DarkRed
        }
        $replicationResults.Failures = $failures.Count
        $replicationResults.Status = "Degraded"
    }
} catch {
    Write-Host "[-] Failed to check replication failures via Cmdlet: $_" -ForegroundColor Red
    $replicationResults.Failures = "Error"
}

# 3. Check replication partner metadata
Write-Host "`n2. Retrieving Replication Partner Metadata..." -ForegroundColor Yellow
try {
    $partners = Get-ADReplicationPartnerMetadata -Target $env:COMPUTERNAME -ErrorAction Stop
    $partnerDetails = @()
    foreach ($partner in $partners) {
        $lastAttempt = $partner.LastReplicationAttempt
        $lastSuccess = $partner.LastReplicationSuccess
        $timeDiff = (Get-Date) - $lastSuccess
        
        Write-Host "[+] Partner: $($partner.Partner)" -ForegroundColor Green
        Write-Host "    Last Successful Sync: $lastSuccess ($([Math]::Round($timeDiff.TotalMinutes)) minutes ago)" -ForegroundColor Green
        Write-Host "    Last Attempt Result: $($partner.LastReplicationResult)" -ForegroundColor Green
        
        $partnerDetails += [PSCustomObject]@{
            Partner     = $partner.Partner
            LastSuccess = $lastSuccess
            LastResult  = $partner.LastReplicationResult
        }
        
        if ($partner.LastReplicationResult -ne 0 -or $timeDiff.TotalHours -gt 1) {
            $replicationResults.Status = "Degraded"
        }
    }
    $replicationResults.Partners = $partnerDetails
} catch {
    Write-Host "[-] Failed to retrieve partner metadata: $_" -ForegroundColor Red
    $replicationResults.Partners = "Error"
}

# 4. Fallback to repadmin command output
Write-Host "`n3. Replication Summary (repadmin /replsummary)..." -ForegroundColor Yellow
try {
    $replSummary = repadmin.exe /replsummary 2>&1
    Write-Host $replSummary -ForegroundColor DarkYellow
} catch {
    Write-Host "[-] Failed to run repadmin.exe tool." -ForegroundColor Red
}

Write-Host "`n--- Replication Health Summary ---" -ForegroundColor Cyan
if ($replicationResults.Status -eq "Healthy") {
    Write-Host "Replication Status: HEALTHY" -ForegroundColor Green
} else {
    Write-Host "Replication Status: DEGRADED or errors present" -ForegroundColor Red
}

return [PSCustomObject]$replicationResults
