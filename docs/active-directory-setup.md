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
| `Join-Domain.ps1` | Joins a Windows host to `corp.lab` using credentials from Parameter Store. | `-DomainName`, `-Credential` |
| `Rename-Computer.ps1` | Renames the machine hostname (e.g., `DC01`, `DC02`) and triggers a reboot if changed. | `-NewName`, `-Restart` |
| `Set-DnsServer.ps1` | Sets static DNS server address on active network interface to primary DC (`10.10.10.10`). | `-DnsServers` |
| `Test-ADHealth.ps1` | Executes comprehensive health tests on Active Directory services and `dcdiag.exe`. | None |

---

### Role Scripts (`powershell/roles/`)

These scripts represent top-level roles that coordinate installation, configuration, and orchestration tasks on each machine.

1. **`DomainController.ps1`**:
   - Installs the Active Directory Domain Services (AD DS) feature.
   - Fetches the DSRM password from AWS SSM Parameter Store.
   - Promotes the server to the Primary Domain Controller by invoking `Promote-Forest.ps1`.
   - Triggers system reboot via the bootstrap framework to activate the DC.
   - Resets the Domain Administrator password (post-reboot).

2. **`AdditionalDomainController.ps1`**:
   - Configures DNS client to point to the Primary DC (`10.10.10.10`).
   - Installs the AD DS feature.
   - Retrieves domain credentials from AWS SSM Parameter Store.
   - Promotes the server to an Additional Domain Controller by invoking `Promote-AdditionalDC.ps1`.
   - Triggers system reboot via the bootstrap framework to activate the replica DC.
   - Validates Active Directory replication (post-reboot).

3. **`FileServer.ps1`**:
   - Installs the File Server role and creates share roots.

---

### DC01 Promotion (`powershell/dc01/`)

1. **`Promote-Forest.ps1`**:
   - Checks if host is already a Domain Controller.
   - Runs `Install-ADDSForest` for domain `corp.lab` using the supplied DSRM password (with auto-reboot disabled).

2. **`Reset-DomainAdministrator.ps1`**:
   - Resets default Domain Administrator password to match SSM Parameter Store value if out of sync.

---

### DC02 Promotion (`powershell/dc02/`)

1. **`Promote-AdditionalDC.ps1`**:
   - Checks if host is already a Domain Controller.
   - Runs `Install-ADDSDomainController` to join existing `corp.lab` domain as a replica DC using the supplied credentials and DSRM password (with auto-reboot disabled).

2. **`Validate-Replication.ps1`**:
   - Checks Active Directory SYSVOL and NTDS replication status between `DC01` and `DC02` using `repadmin /replsummary` and `Get-ADReplicationPartnerMetadata`.

---

## Instance Directory Structure & Script Locations

During provisioning, PowerShell scripts are deployed to a standardized automation location on Windows instances:

- **Primary Automation Path**: `C:\Automation\powershell\`
  - `C:\Automation\powershell\common\Test-ADHealth.ps1`
  - `C:\Automation\powershell\common\Get-DomainCredential.ps1`
- **Legacy / Bootstrap Path**: `C:\bootstrap\`

---

## Bootstrap State Machine Engine

The bootstrap process operates as a state machine governed by the orchestrator script `Continue-Bootstrap.ps1` and configuration `Bootstrap-State.ps1`.

### Valid Stages
All valid stages are defined centrally in `Bootstrap-State.ps1`:
*   `Initial`: Represents a fresh boot. Typically handles computer renaming.
*   `DomainJoinPending`: Handles joining the server to the Active Directory domain `corp.lab`.
*   `PromotionPending`: Installs AD DS features and promotes the machine to a DC or replica DC.
*   `PostPromotionPending`: Performs post-promotion operations (like DSRM/Administrator password resetting or replication verification).
*   `RoleConfigurationPending`: Installs custom roles (e.g. File Server configuration).
*   `Complete`: Signifies provisioning has successfully completed; the engine removes its boot-time scheduled tasks.

### Workflow & Dispatch
1.  **Initialization**: `Bootstrap.ps1` writes the initial state JSON to `C:\ProgramData\Bootstrap\state.json` and registers a startup scheduled task targeting `Continue-Bootstrap.ps1`.
2.  **Execution Loop**: On execution, `Continue-Bootstrap.ps1` reads the current stage, validates it against the schema, and dispatches the work to the respective role script (e.g. `DomainController.ps1`) with the `-Stage` parameter.
3.  **Transitions & Reboots**: Role scripts perform stage-specific tasks and return a status map containing the `NextStage` and a `RebootRequired` flag. The engine updates the stage in the state file and handles reboots centrally.

---

## Health Check & Verification Commands

### Method 1: Dynamic Execution via Bash Wrapper (Recommended)

Run `./scripts/health-check.sh` from your local Linux workstation. The script dynamically streams the local repository script content directly to the target instance via AWS SSM:

```bash
# Execute full validation suite on DC01
./scripts/health-check.sh DC01 --script ./powershell/validation/Test-Lab.ps1

# Execute specific validation test (AD Health, Replication, DNS, GPO, File Server)
./scripts/health-check.sh DC01 --script ./powershell/validation/Test-ADHealth.ps1
./scripts/health-check.sh DC02 --script ./powershell/validation/Test-Replication.ps1
./scripts/health-check.sh DC01 --script ./powershell/validation/Test-DNS.ps1
./scripts/health-check.sh DC01 --script ./powershell/validation/Test-GPO.ps1
./scripts/health-check.sh FS01 --script ./powershell/validation/Test-FileServer.ps1
```

### Method 2: Manual Execution via SSM Session Manager

Connect to the instance via SSM Session Manager and invoke the script directly from the standard automation path:

```powershell
# Execute full lab validation suite on instance
& C:\Automation\powershell\validation\Test-Lab.ps1

# Execute individual validation scripts
& C:\Automation\powershell\validation\Test-ADHealth.ps1
& C:\Automation\powershell\validation\Test-Replication.ps1
& C:\Automation\powershell\validation\Test-DNS.ps1
& C:\Automation\powershell\validation\Test-GPO.ps1
& C:\Automation\powershell\validation\Test-FileServer.ps1
```

**Expected Output**:
- Services (`NTDS`, `DNS`, `Kdc`, `ADWS`, `DFSR`): **Running**
- Active Directory Module: **Loaded**
- DCDiag Services & Replication: **Pass**
- Active Directory Replication: **0 Errors across 5 Naming Contexts**
- DNS Resolution: **`corp.lab`, `DC01`, `DC02`, `FS01` resolved**
- Group Policy RSOP: **Computer baseline and domain policies applied**
- File Share Permissions: **SMB shares and NTFS ACLs verified**
- Overall AD Health: **PASS**

---
*Next guide: [Security & Networking Guide](file:///home/it/aws-active-directory-lab/docs/security-and-networking.md)*
