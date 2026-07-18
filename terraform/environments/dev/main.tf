module "networking" {
  source = "../../modules/networking"

  project_name = var.project_name
  environment  = var.environment

  vpc_cidr = "10.10.0.0/16"

  public_subnet_cidr    = "10.10.1.0/24"
  private_subnet_a_cidr = "10.10.10.0/24"
  private_subnet_b_cidr = "10.10.20.0/24"

  availability_zone_a = "ap-south-1a"
  availability_zone_b = "ap-south-1b"

  tags = local.common_tags
}

module "identity" {
  source = "../../modules/identity"

  project_name = var.project_name
  environment  = var.environment

  tags = local.common_tags
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment

  vpc_id   = module.networking.vpc_id
  vpc_cidr = "10.10.0.0/16"

  tags = local.common_tags
}
