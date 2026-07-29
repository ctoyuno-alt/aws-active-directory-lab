# AWS Active Directory Lab

An automated Infrastructure as Code (IaC) deployment for setting up an Active Directory (AD) Lab on Amazon Web Services (AWS). This lab environment is designed for security testing, administration practice, and hybrid cloud integration scenarios.

---

## Documentation Index

The repository contains comprehensive documentation covering architecture, deployment, active directory configuration, security, and troubleshooting:

- 🏗️ [**System Architecture Guide**](docs/architecture.md): Deep-dive into network topology, VPC subnets, Domain Controllers (`DC01`, `DC02`), and AWS management integration.
- 🚀 [**Deployment & Setup Guide**](docs/deployment-guide.md): Step-by-step guide covering prerequisites, state bootstrapping S3/DynamoDB, and Terraform execution.
- ⚙️ [**Active Directory Setup Guide**](docs/active-directory-setup.md): Forest promotion (`corp.lab`), replica DC join, PowerShell automation suite, and health checks.
- 🔒 [**Security & Networking Architecture**](docs/security-and-networking.md): Network perimeter controls, zero open inbound internet ports, SSM Parameter Store integration, and CloudWatch log shipping.
- 🔧 [**Troubleshooting & Operational Guide**](docs/troubleshooting.md): Diagnostics checklist, SSM connection troubleshooting, AD replication errors, and state lock fixes.

---

## Architecture Overview

The infrastructure deployed by this repository includes:
* **Custom VPC**: Multi-AZ network setup spanning `ap-south-1a` and `ap-south-1b` with private subnets (`10.10.10.0/24`, `10.10.20.0/24`).
* **Active Directory Domain Controllers**: Hosted on AWS EC2 Windows Server instances (`DC01` at `10.10.10.10` and `DC02` at `10.10.20.10`).
* **IAM & SSM Integration**: Least-privileged roles and policies for AWS Systems Manager (SSM) Session Manager access without opening public RDP/SSH ports.
* **Automated PowerShell Suite**: Reusable scripts for domain forest promotion, joining domain, DNS configuration, and AD health checks.
* **CloudWatch Logging**: Automated Windows Event Log streaming (System, Security, Directory Service) and system performance metrics.

---

## Repository Structure

```text
├── bootstrap/                    # Terraform state initialization (S3 bucket & DynamoDB lock table)
├── cloudwatch/                   # CloudWatch agent JSON metrics and Windows Event Log config
├── docs/                         # Detailed architecture, setup guides, and walkthroughs
│   ├── active-directory-setup.md # AD Forest promotion, join, and PowerShell automation
│   ├── architecture.md           # Network topology, VPC design, and domain layout
│   ├── deployment-guide.md       # Step-by-step deployment and Terraform usage
│   ├── security-and-networking.md# Security groups, IAM, SSM Parameters, CloudWatch
│   └── troubleshooting.md        # Troubleshooting procedures and diagnostic commands
├── powershell/                   # PowerShell scripts for AD configuration and automation
│   ├── common/                   # Reusable helper scripts (DNS, Credentials, Health, Join, Rename)
│   ├── dc01/                     # DC01 forest promotion and admin reset scripts
│   └── dc02/                     # DC02 additional DC promotion and replication validation
├── scripts/                      # Helper automation scripts
├── terraform/                    # Infrastructure as Code
│   ├── environments/
│   │   └── dev/                  # Development environment configuration
│   └── modules/                  # Modular Terraform infrastructure components
│       ├── compute/              # EC2 instances (Domain Controllers)
│       ├── endpoints/            # VPC Interface Endpoints (SSM, SSMMessages, EC2Messages)
│       ├── identity/             # IAM roles, policies, and instance profiles
│       ├── monitoring/           # CloudWatch Log Group configuration
│       ├── networking/           # VPC and subnet routing setup
│       ├── security/             # Security groups and rules
│       └── ssm/                  # SSM Parameter Store entries for AD credentials
└── userdata/                     # Bootstrapping user_data scripts for instances
    ├── linux/                    # Linux userdata scripts
    └── windows/                  # Windows Server userdata / PowerShell bootstrap scripts
```

---

## Getting Started

### Prerequisites

* [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials.
* [Terraform](https://www.terraform.io/) (v1.13.0+) installed locally.
* Basic knowledge of AWS networking and Windows Server Active Directory.

### Quick Start Summary

1. **Initialize Backend / Remote State**:
   ```bash
   cd bootstrap
   terraform init && terraform apply
   ```

2. **Deploy Development Environment**:
   ```bash
   cd ../terraform/environments/dev
   terraform init
   terraform apply
   ```

3. **Connect via AWS SSM Session Manager**:
   ```bash
   aws ssm start-session --target <DC01-INSTANCE-ID>
   ```

For full setup instructions, see the [Deployment & Setup Guide](docs/deployment-guide.md).

---

## Security Disclaimer

This environment is designed for lab and testing purposes. Do not deploy this configuration in production without performing a thorough security review and adapting configurations (such as passwords, security groups, and public routing) to align with enterprise security standards.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
