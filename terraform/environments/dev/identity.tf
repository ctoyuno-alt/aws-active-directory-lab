module "identity" {
  source = "../../modules/identity"

  project_name = var.project_name
  environment  = var.environment

  tags = local.common_tags
}