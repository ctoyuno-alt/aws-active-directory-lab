terraform {
  required_version = ">= 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
terraform {
  required_version = ">= 1.13.0"

  backend "s3" {
    bucket         = "aws-active-directory-lab-420411424420-tfstate"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "aws-active-directory-lab-terraform-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
