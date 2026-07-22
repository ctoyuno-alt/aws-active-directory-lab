module "ssm" {
  source = "../../modules/ssm"

  domain_admin_username = var.domain_admin_username
  domain_admin_password = var.domain_admin_password
}