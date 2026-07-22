resource "aws_ssm_parameter" "domain_admin_username" {
  name  = "/ad/corp.lab/domain-admin-username"
  type  = "String"
  value = var.domain_admin_username
}

resource "aws_ssm_parameter" "domain_admin_password" {
  name  = "/ad/corp.lab/domain-admin-password"
  type  = "SecureString"
  value = var.domain_admin_password
}