module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment

  vpc_id   = module.networking.vpc_id
  vpc_cidr = "10.10.0.0/16"

  tags = local.common_tags
}