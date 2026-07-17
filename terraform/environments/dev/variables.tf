variable "project_name" {
  default = "aws-active-directory-lab"
}

variable "environment" {
  default = "dev"
}

variable "aws_region" {
  default = "ap-south-1"
}

variable "aws_profile" {
  type    = string
  default = ""
}
