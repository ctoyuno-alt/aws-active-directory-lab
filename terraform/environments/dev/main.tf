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

module "dc01" {
  source = "../../modules/compute"

  project_name = var.project_name
  environment  = var.environment
  name         = "dc01"

  ami_id        = data.aws_ami.windows_server.id
  instance_type = var.dc01_instance_type

  subnet_id  = module.networking.private_subnet_a_id
  private_ip = var.dc01_private_ip

  security_group_ids = [
    module.security.domain_controller_sg_id
  ]

  instance_profile_name = module.identity.instance_profile_name

  root_volume_size = var.dc01_root_volume_size

  user_data = file("${path.root}/../../../userdata/windows/windows-bootstrap.ps1")

  tags = local.common_tags
}
