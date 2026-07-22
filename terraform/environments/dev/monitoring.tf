module "monitoring" {
  source = "../../modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  instance_id = module.dc01.instance_id

  log_retention_days = 30

  tags = local.common_tags
}