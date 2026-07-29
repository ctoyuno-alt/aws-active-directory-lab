# Deployment & Setup Guide

This guide details the step-by-step procedure for deploying the **AWS Active Directory Lab** from scratch using Terraform and PowerShell automation scripts.

---

## Prerequisites

Before beginning deployment, ensure the following tools are installed and configured:

1. **AWS CLI v2**: Installed and authenticated with an AWS profile (`aws-ad-lab` or default).
2. **Terraform**: Version `>= 1.13.0`.
3. **IAM Permissions**: Permissions to create VPCs, Subnets, EC2 Instances, IAM Roles, SSM Parameters, CloudWatch Log Groups, S3 Buckets, and DynamoDB tables.

---

## Deployment Steps

### Step 1: Bootstrap Remote State Infrastructure

The `bootstrap/` directory provisions the S3 bucket and DynamoDB table required for Terraform state persistence and locking.

```bash
# Navigate to the bootstrap directory
cd bootstrap

# Initialize Terraform
terraform init

# Review execution plan
terraform plan

# Deploy remote state resources
terraform apply -auto-approve
```

### Step 2: Configure Environment Variables

Navigate to the development environment configuration directory:

```bash
cd ../terraform/environments/dev
```

Create or update `terraform.tfvars`:

```hcl
aws_region             = "ap-south-1"
aws_profile            = "aws-ad-lab"
project_name           = "aws-active-directory-lab"
environment            = "dev"
dc01_instance_type     = "t3.micro"
dc01_private_ip        = "10.10.10.10"
dc02_instance_type     = "t3.micro"
dc02_private_ip        = "10.10.20.10"
domain_admin_username  = "Administrator"
domain_admin_password  = "P@ssw0rd123456!" # Ensure strong password meeting AD policy
```

> [!WARNING]
> Do not commit `terraform.tfvars` containing secrets to public version control repositories.

### Step 3: Provision AWS Infrastructure with Terraform

```bash
# Initialize Terraform dev environment
terraform init

# Validate configuration syntax
terraform validate

# Provision infrastructure
terraform apply
```

This provisions:
- Custom VPC, Subnets, Internet Gateway, Route Tables
- VPC Endpoints for SSM, SSMMessages, EC2Messages
- IAM Roles & Instance Profiles for Windows EC2 instances
- SSM Secure Parameters for Active Directory credentials
- EC2 Windows Server instances (`DC01`, `DC02`)
- CloudWatch Log Group for monitoring

### Step 4: Verify Deployment Outputs

Upon successful completion, Terraform outputs key resource information:

```bash
Outputs:

dc01_instance_id       = "i-0123456789abcdef0"
dc01_private_dns      = "ip-10-10-10-10.ap-south-1.compute.internal"
dc01_private_ip       = "10.10.10.10"
domain_controller_sg_id = "sg-0123456789abcdef0"
instance_profile_name = "aws-active-directory-lab-dev-instance-profile"
vpc_id                 = "vpc-0123456789abcdef0"
```

---

## Connection & Management

Since instances reside in private subnets with no public IP or direct RDP access, connect via AWS SSM Session Manager:

```bash
# Start an SSM session to DC01
aws ssm start-session --target i-0123456789abcdef0 --region ap-south-1

# Start a PowerShell session via SSM
aws ssm start-session \
    --target i-0123456789abcdef0 \
    --document-name AWS-StartPSSession \
    --region ap-south-1
```

---
*Next guide: [Active Directory Setup Guide](file:///home/it/aws-active-directory-lab/docs/active-directory-setup.md)*
