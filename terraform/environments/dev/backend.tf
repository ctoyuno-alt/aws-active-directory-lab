terraform {
  backend "s3" {
    bucket         = "aws-active-directory-lab-420411424420-tfstate"
    key            = "environments/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "aws-active-directory-lab-terraform-lock"
    encrypt        = true
  }
}
