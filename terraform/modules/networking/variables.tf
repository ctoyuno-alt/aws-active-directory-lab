variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
}

variable "private_subnet_a_cidr" {
  description = "Private subnet A CIDR"
  type        = string
}

variable "private_subnet_b_cidr" {
  description = "Private subnet B CIDR"
  type        = string
}

variable "availability_zone_a" {
  description = "Primary Availability Zone"
  type        = string
}

variable "availability_zone_b" {
  description = "Secondary Availability Zone"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
}
