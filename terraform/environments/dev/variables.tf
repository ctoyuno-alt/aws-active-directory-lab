variable "project_name" {
  type    = string
  default = "aws-active-directory-lab"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "aws_profile" {
  type    = string
  default = ""
}

variable "dc01_instance_type" {
  description = "Instance type for Domain Controller"
  type        = string
  default     = "t3.micro"
}

variable "dc01_private_ip" {
  description = "Private IP address for Domain Controller"
  type        = string
  default     = "10.10.10.10"
}

variable "dc01_root_volume_size" {
  description = "Root EBS volume size (GB)"
  type        = number
  default     = 100
}

variable "dc01_key_name" {
  description = "EC2 Key Pair"
  type        = string
  default     = null
}

variable "dc02_instance_type" {
  description = "EC2 instance type for DC02"
  type        = string
  default     = "t3.micro"
}

variable "dc02_private_ip" {
  description = "Private IP address for DC02"
  type        = string
  default     = "10.10.20.10"
}

variable "dc02_root_volume_size" {
  description = "Root volume size for DC02"
  type        = number
  default     = 100
}