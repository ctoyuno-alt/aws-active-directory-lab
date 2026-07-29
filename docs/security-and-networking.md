# Security & Networking Architecture

This document describes the security controls, access management, network isolation, credential management, and observability design implemented in the **AWS Active Directory Lab**.

---

## Network Isolation & Security Groups

### Security Perimeter

The architecture enforces strict network isolation with **Zero Open Inbound Internet Ports**:

- **No Public IPs**: Domain Controllers are placed strictly in Private Subnets (`10.10.10.0/24` and `10.10.20.0/24`).
- **No Inbound Public SSH/RDP**: Security groups block all public ingress from `0.0.0.0/0`.
- **Private Link / Endpoints**: All AWS service traffic (SSM, KMS, CloudWatch) flows through VPC Interface Endpoints without traversing the public Internet.

### Security Group Ingress / Egress Rules

```
+-----------------------------------------------------------------------------------+
| Security Group: dc_sg (Domain Controller SG)                                     |
+------------------+---------------+----------------+-------------------------------+
| Direction        | Protocol/Port | Source/Dest    | Purpose                       |
+------------------+---------------+----------------+-------------------------------+
| Ingress          | TCP/UDP 53    | 10.10.0.0/16   | DNS Resolution                |
| Ingress          | TCP/UDP 88    | 10.10.0.0/16   | Kerberos Authentication       |
| Ingress          | TCP/UDP 135   | 10.10.0.0/16   | RPC Endpoint Mapper           |
| Ingress          | TCP/UDP 389   | 10.10.0.0/16   | LDAP                          |
| Ingress          | TCP 445       | 10.10.0.0/16   | SMB / SYSVOL                  |
| Ingress          | TCP 636       | 10.10.0.0/16   | LDAPS                         |
| Ingress          | TCP 3268/3269 | 10.10.0.0/16   | Global Catalog / GC SSL       |
| Ingress          | TCP 3389      | 10.10.0.0/16   | RDP (Internal VPC only)       |
| Egress           | All (0.0.0.0) | 0.0.0.0/0      | Outbound access (VPC & AWS)   |
+------------------+---------------+----------------+-------------------------------+
```

---

## IAM & Credential Management

### IAM Least Privilege

1. **EC2 Instance Profile (`aws-active-directory-lab-dev-instance-profile`)**:
   - `AmazonSSMManagedInstanceCore`: Enables SSM Session Manager shell connectivity.
   - `CloudWatchAgentServerPolicy`: Grants rights to stream OS metrics and Windows Event Logs to CloudWatch.
   - Inline SSM Policy: Grants `ssm:GetParameter` and `ssm:GetParameters` specifically for path `/ad/corp.lab/*`.

### AWS Systems Manager Parameter Store

Sensitive credentials are automatically provisioned into Parameter Store during Terraform apply:

- `/ad/corp.lab/domain-admin-username` (`String`: `Administrator`)
- `/ad/corp.lab/domain-admin-password` (`SecureString`, encrypted with AWS KMS key)

PowerShell scripts on the EC2 instances dynamically fetch these credentials at boot time using AWS Tools for PowerShell (`Get-SSMParameterValue`).

---

## Observability & CloudWatch Integration

### CloudWatch Agent Configuration (`cloudwatch/windows-agent-config.json`)

Domain Controllers run the Amazon CloudWatch Agent to capture Windows Event Logs and system performance metrics:

- **Log Group**: `/aws/ec2/aws-active-directory-lab-dev/dc01`
- **Captured Event Logs**:
  - `System`: OS system events and errors.
  - `Security`: Audit events, login attempts, credential validations.
  - `Directory Service`: Active Directory Domain Services events and replication status.
- **Metrics Tracked**: CPU utilization, Memory usage (`Available MBytes`), LogicalDisk free space (`% Free Space`).

---
*Next guide: [Troubleshooting Guide](file:///home/it/aws-active-directory-lab/docs/troubleshooting.md)*
