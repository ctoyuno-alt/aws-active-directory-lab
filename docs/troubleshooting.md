# Troubleshooting & Operational Guide

This document provides diagnosis steps and resolutions for common issues encountered during deployment or operation of the **AWS Active Directory Lab**.

---

## Quick Diagnostic Checklist

When encountering issues, run these diagnostic steps in order:

```powershell
# 1. Verify SSM Agent Status
Get-Service AmazonSSMAgent

# 2. Test AD Health & Services
.\powershell\common\Test-ADHealth.ps1

# 3. Test Domain Connectivity & DNS Resolution
Resolve-DnsName corp.lab

# 4. Check Active Directory Replication Status
repadmin /replsummary
```

---

## Common Issues & Solutions

### 1. SSM Session Manager Connection Failure

**Symptom**: `aws ssm start-session` fails with `TargetNotConnected` or times out.

**Root Causes & Solutions**:
- **VPC Endpoints Missing/Misconfigured**: Ensure VPC endpoints (`ssm`, `ssmmessages`, `ec2messages`) are associated with private subnets and security groups allow HTTPS (port 443) from VPC CIDR `10.10.0.0/16`.
- **IAM Profile Missing**: Verify instance profile `aws-active-directory-lab-dev-instance-profile` is attached to the EC2 instance.
- **SSM Agent Not Running**: Check SSM agent log in `C:\ProgramData\Amazon\SSM\Logs\errors.log`.

---

### 2. DC02 Fails to Join Domain or Promote

**Symptom**: `Promote-AdditionalDC.ps1` errors with `The specified domain either does not exist or could not be contacted`.

**Root Causes & Solutions**:
- **DNS Configuration**: DC02 must point to DC01's private IP (`10.10.10.10`) as its primary DNS server before domain join. Verify by running `Get-DnsClientServerAddress`.
- **DC01 Promotion Not Finished**: DC01 must finish forest promotion and reboot before DC02 can join. Check DC01 status via SSM session.
- **Security Group Ingress**: Ensure `dc_sg` security group allows RPC (135), Kerberos (88), and DNS (53) traffic between private subnets.

---

### 3. Active Directory Replication Errors

**Symptom**: `Validate-Replication.ps1` or `repadmin /showrepl` shows replication errors (e.g., Error 8453, Error 1722).

**Root Causes & Solutions**:
- **DNS Resolution**: Run `Resolve-DnsName _msdcs.corp.lab` on DC02 to ensure it resolves the forest GUID CNAME records.
- **Time Synchronization**: Ensure both DC01 and DC02 clocks are synchronized with AWS Time Sync Service (`169.254.169.123`). Run `w32tm /query /status`.

---

### 4. Terraform State Lock Failure

**Symptom**: `terraform apply` fails with `Error acquiring the state lock` in DynamoDB.

**Root Cause & Solution**:
- A previous Terraform operation crashed or was interrupted.
- Run `terraform force-unlock <LOCK-ID>` after verifying no other team member or pipeline is actively running `apply`.

### 5. Failed to Create User `ssm-user` on Domain Controller

**Symptom**: `aws ssm start-session` fails with:
`Unable to start command: Failed to create user ssm-user: Instance is running active directory domain controller service.`

**Root Cause**:
Active Directory Domain Controllers disable local SAM user accounts (`Win32_UserAccount`). When AWS SSM Session Manager attempts to create a local OS user named `ssm-user` via local SAM APIs, Windows rejects the request because user management must be performed in Active Directory.

**Solutions**:
- **Solution A (Recommended)**: Create `ssm-user` in Active Directory using the provided automation script via SSM RunCommand:
  ```bash
  ./scripts/health-check.sh DC01 --script ./powershell/common/Initialize-SSMUser.ps1
  ./scripts/health-check.sh DC02 --script ./powershell/common/Initialize-SSMUser.ps1
  ```
- **Solution B (Remote Diagnostics)**: Run scripts remotely via `./scripts/health-check.sh`, which executes under `NT AUTHORITY\SYSTEM` and bypasses OS user creation completely.

---
*Back to: [Architecture Overview](file:///home/it/aws-active-directory-lab/docs/architecture.md) | [Deployment Guide](file:///home/it/aws-active-directory-lab/docs/deployment-guide.md)*
