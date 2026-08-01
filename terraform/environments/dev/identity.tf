module "identity" {
  source = "../../modules/identity"

  project_name  = var.project_name
  environment   = var.environment
  bootstrap_arn = module.bootstrap.bootstrap_arn

  tags = local.common_tags
}