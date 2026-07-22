module "endpoints" {
  source = "../../modules/endpoints"

  project_name = var.project_name
  environment  = var.environment

  vpc_id                 = module.networking.vpc_id
  vpc_cidr               = "10.10.0.0/16"
  private_route_table_id = module.networking.private_route_table_id

  private_subnet_ids = [
    module.networking.private_subnet_a_id,
    module.networking.private_subnet_b_id
  ]

  tags = local.common_tags
}
