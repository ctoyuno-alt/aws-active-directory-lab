module "windows_servers" {
  for_each = local.windows_servers

  source = "../../modules/compute"

  project_name = var.project_name
  environment  = var.environment

  ami_id        = data.aws_ami.windows_server.id
  instance_type = each.value.instance_type

  subnet_id  = each.value.subnet_id
  private_ip = each.value.private_ip

  security_group_ids = [
    module.security.domain_controller_sg_id
  ]

  instance_profile_name = module.identity.instance_profile_name

  root_volume_size = each.value.root_volume_size

  user_data = each.value.user_data

  tags = local.common_tags

  hostname = each.value.hostname
  role     = each.value.role
}
