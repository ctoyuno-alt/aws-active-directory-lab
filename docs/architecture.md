# System Architecture Documentation

## Overview

The **AWS Active Directory Lab** provides an automated Infrastructure as Code (IaC) deployment for a multi-availability zone Windows Active Directory environment on Amazon Web Services (AWS). It is designed to emulate an enterprise Active Directory domain architecture suitable for testing, security auditing, credential testing, and hybrid cloud integration.

## Network Topology & VPC Design

The infrastructure is deployed inside a dedicated Virtual Private Cloud (VPC) spanning multiple Availability Zones (AZs) in `ap-south-1` (configurable):

- **VPC CIDR**: `10.10.0.0/16`
- **Public Subnet**: `10.10.1.0/24` (Internet-facing routing, NAT Gateway optional)
- **Private Subnet A**: `10.10.10.0/24` (Availability Zone `ap-south-1a`)
- **Private Subnet B**: `10.10.20.0/24` (Availability Zone `ap-south-1b`)

```
               +-------------------------------------------------------------+
               |                  AWS VPC (10.10.0.0/16)                     |
               |                                                             |
               |  +-------------------------------------------------------+  |
               |  |              Public Subnet (10.10.1.0/24)             |  |
               |  |        - Internet Gateway / Route Tables              |  |
               |  +-------------------------------------------------------+  |
               |                                                             |
               |  +---------------------------+ +-------------------------+  |
               |  | Private Subnet A          | | Private Subnet B        |  |
               |  | (10.10.10.0/24 - AZ 1a)   | | (10.10.20.0/24 - AZ 1b)|  |
               |  |                           | |                         |  |
               |  |  +---------------------+  | |  +-------------------+  |  |
               |  |  |   DC01 (10.10.10.10)  |  | |  | DC02 (10.10.20.10)|  |  |
               |  |  |  Primary Domain     |  | |  | Replica Domain    |  |  |
               |  |  |  Controller        |<===>| Replica Controller|  |  |
               |  |  +---------------------+  | |  +-------------------+  |  |
               |  +---------------------------+ +-------------------------+  |
               |                                                             |
               |  +-------------------------------------------------------+  |
               |  |                 VPC Endpoints (PrivateLink)           |  |
               |  |  - com.amazonaws.ap-south-1.ssm                       |  |
               |  |  - com.amazonaws.ap-south-1.ssmmessages               |  |
               |  |  - com.amazonaws.ap-south-1.ec2messages                |  |
               |  +-------------------------------------------------------+  |
               +-------------------------------------------------------------+
```

## Active Directory Domain Layout

- **Domain Name**: `corp.lab`
- **Forest Functional Level**: Windows Server 2016 / 2022
- **Domain Controller 1 (`DC01`)**:
  - **Hostname**: `DC01`
  - **Private IP**: `10.10.10.10`
  - **Roles**: Primary Domain Controller, Forest Root, DNS Server, Global Catalog, FSMO Role Holder.
- **Domain Controller 2 (`DC02`)**:
  - **Hostname**: `DC02`
  - **Private IP**: `10.10.20.10`
  - **Roles**: Additional/Replica Domain Controller, Secondary DNS Server, Global Catalog.

## AWS Management & Integration Layer

1. **AWS Systems Manager (SSM) Integration**:
   - Zero open inbound public ports.
   - Private connectivity managed via AWS SSM Session Manager over interface VPC Endpoints.
2. **SSM Parameter Store**:
   - Stores domain administrative credentials securely (`/ad/corp.lab/domain-admin-username`, `/ad/corp.lab/domain-admin-password`).
3. **CloudWatch Logs**:
   - CloudWatch agent installed on Domain Controllers sending Event Logs (System, Security, Directory Service) to `/aws/ec2/aws-active-directory-lab-dev/dc01`.
4. **Terraform Remote State**:
   - S3 Bucket for backend state persistence with SSE-KMS encryption.
   - DynamoDB table for state locking and consistency checks.

---
*Next guide: [Deployment Guide](file:///home/it/aws-active-directory-lab/docs/deployment-guide.md)*
