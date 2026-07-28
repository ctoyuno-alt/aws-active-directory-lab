terraform {
  required_version = ">= 1.13.0"

  backend "s3" {
    bucket         = "aws-active-directory-lab-808644003214-tfstate"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "aws-active-directory-lab-terraform-lock"
    profile        = "aws-ad-lab"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}