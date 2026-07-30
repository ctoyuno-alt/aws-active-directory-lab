module "dc01" {
  source = "../../modules/compute"

  project_name = var.project_name
  environment  = var.environment

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

  hostname = "DC01"

  role = "DomainController"
}