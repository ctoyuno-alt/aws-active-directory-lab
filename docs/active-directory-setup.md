# Active Directory Setup & Configuration Guide

This document describes the PowerShell automation workflow used to promote Domain Controllers, join member servers, configure DNS, and verify Active Directory replication and health.

---

## PowerShell Automation Workflow

The PowerShell scripts in `powershell/` automate the setup of the Active Directory domain `corp.lab`.

```
               DC01 Boot & Promotion               DC02 Boot & Join
              +---------------------+            +--------------------+
              | windows-bootstrap   |            | join-dc02.ps1      |
              +----------+----------+            +---------+----------+
                         |                                 |
                         v                                 v
              +---------------------+            +--------------------+
              | Rename-Computer     |            | Set-DnsServer      |
              | Hostname: DC01      |            | Point to 10.10.10.10|
              +----------+----------+            +---------+----------+
                         |                                 |
                         v                                 v
              +---------------------+            +--------------------+
              | Promote-Forest      |            | Join-Domain        |
              | Domain: corp.lab    |            | Join corp.lab      |
              +----------+----------+            +---------+----------+
                         |                                 |
                         v                                 v
              +---------------------+            +--------------------+
              | System Reboot       |            | Promote-           |
              | Active Directory UP |            | AdditionalDC       |
              +---------------------+            +---------+----------+
                                                           |
                                                           v
                                                 +--------------------+
                                                 | System Reboot      |
                                                 | Replica DC Active  |
                                                 +--------------------+
```

---

## Script Inventory & Details

### Common Helper Scripts (`powershell/common/`)

| Script | Purpose | Parameters |
|---|---|---|
| `Get-DomainCredential.ps1` | Retrieves domain admin credentials from AWS SSM Parameter Store and returns `PSCredential`. | `-UsernameParameter`, `-PasswordParameter` |
| `Install-ADDSFeature.ps1` | Ensures the `AD-Domain-Services` Windows Feature and RSAT tools are installed. | None |
| `Join-Domain.ps1` | Joins a Windows host to `corp.lab` using credentials from Parameter Store. | `-DomainName`, `-Credential`, `-Restart` |
| `Rename-Computer.ps1` | Renames the machine hostname (e.g., `DC01`, `DC02`) and triggers a reboot if changed. | `-NewName`, `-Restart` |
| `Set-DnsServer.ps1` | Sets static DNS server address on active network interface to primary DC (`10.10.10.10`). | `-DnsServers` |
| `Test-ADHealth.ps1` | Executes comprehensive health tests on Active Directory services and `dcdiag.exe`. | None |

---

### DC01 Promotion (`powershell/dc01/`)

1. **`Promote-Forest.ps1`**:
   - Checks if host is already a Domain Controller.
   - Installs `AD-Domain-Services` feature.
   - Fetches DSRM / Domain Admin password from Parameter Store parameter `/ad/corp.lab/domain-admin-password`.
   - Runs `Install-ADDSForest` for domain `corp.lab`.
   - Triggers an automated system reboot.

2. **`Reset-DomainAdministrator.ps1`**:
   - Resets default Domain Administrator password to match SSM Parameter Store value if out of sync.

---

### DC02 Promotion (`powershell/dc02/`)

1. **`Promote-AdditionalDC.ps1`**:
   - Configures DNS client to point to Primary DC (`10.10.10.10`).
   - Ensures `AD-Domain-Services` feature is installed.
   - Retrieves credentials from Parameter Store via `Get-DomainCredential.ps1`.
   - Runs `Install-ADDSDomainController` to join existing `corp.lab` domain as a replica DC.
   - Triggers automated reboot.

2. **`Validate-Replication.ps1`**:
   - Checks Active Directory SYSVOL and NTDS replication status between `DC01` and `DC02` using `repadmin /replsummary` and `Get-ADReplicationPartnerMetadata`.

---

## Health Check & Verification Commands

After deployment, execute the following health checks via AWS SSM Session Manager:

### Run Health Diagnostic

```powershell
# Execute health check script
.\powershell\common\Test-ADHealth.ps1
```

**Expected Output**:
- Services (`NTDS`, `DNS`, `Kdc`, `ADWS`, `DFSR`): **Running**
- Active Directory Module: **Loaded**
- DCDiag Services & Replication: **Pass**
- Overall AD Health: **PASS**

### Run Replication Diagnostic

```powershell
# Execute replication validation script on DC02
.\powershell\dc02\Validate-Replication.ps1
```

---
*Next guide: [Security & Networking Guide](file:///home/it/aws-active-directory-lab/docs/security-and-networking.md)*
