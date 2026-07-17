# AWS Active Directory Lab

An automated Infrastructure as Code (IaC) deployment for setting up an Active Directory (AD) Lab on Amazon Web Services (AWS). This lab environment is designed for security testing, administration practice, and hybrid cloud integration scenarios.

## Architecture Overview

The infrastructure deployed by this repository includes:
* **Custom VPC**: Multi-AZ network setup with public and private subnets.
* **Active Directory Domain Controllers**: Hosted on AWS EC2 Windows Server instances within private subnets.
* **Linux Workstations / Member Servers**: Deployed in private/public subnets for domain-joining and administrative operations.
* **IAM Integration**: Least-privileged roles and policies for AWS Systems Manager (SSM) management.
* **Secure Access**: Configured with security groups preventing direct internet exposure, utilizing AWS SSM Session Manager for secure shell access.

## Repository Structure

```text
├── bootstrap/                    # Scripts and state initialization for bootstrapping the lab
├── docs/                         # Detailed architecture, setup guides, and walkthroughs
├── powershell/                   # PowerShell scripts for AD configuration and automation
├── scripts/                      # Bash and other helper automation scripts
├── terraform/                    # Infrastructure as Code
│   ├── environments/
│   │   └── dev/                  # Development/Testing environment configuration
│   └── modules/                  # Reusable Terraform modules
│       ├── ec2/                  # EC2 instances (Domain Controllers & Client machines)
│       ├── iam/                  # IAM roles, policies, and instance profiles
│       ├── security-group/       # Security groups and rules
│       └── vpc/                  # VPC and networking setup
└── userdata/                     # Bootstrap configurations for instances
    ├── linux/                    # Linux userdata scripts
    └── windows/                  # Windows Server userdata / PowerShell bootstrap scripts
```

## Getting Started

### Prerequisites

* [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials.
* [Terraform](https://www.terraform.io/) (v1.0.0+) installed locally.
* Basic knowledge of AWS networking and Windows Server Active Directory.

### Quick Start

1. **Initialize Terraform Backend / Bootstrap**:
   Check the `bootstrap/` directory to configure state storage (S3/DynamoDB if desired).
   
2. **Deploy the Dev Environment**:
   ```bash
   cd terraform/environments/dev
   terraform init
   terraform apply
   ```

3. **Domain Configuration**:
   Once the Windows instances are provisioned, execution scripts in `userdata/windows/` and `powershell/` will configure Active Directory Domain Services (AD DS).

## Security Disclaimer

This environment is designed for lab and testing purposes. Do not deploy this configuration in production without performing a thorough security review and adapting configurations (such as passwords, security groups, and public routing) to align with enterprise security standards.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
