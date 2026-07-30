output "vpc_id" {
  value = module.networking.vpc_id
}
output "instance_profile_name" {
  value = module.identity.instance_profile_name
}
output "domain_controller_sg_id" {
  value = module.security.domain_controller_sg_id
}
output "dc01_instance_id" {
  value = module.windows_servers["dc01"].instance_id
}

output "dc01_private_ip" {
  value = module.windows_servers["dc01"].private_ip
}

output "dc01_private_dns" {
  value = module.windows_servers["dc01"].private_dns
}

output "dc02_instance_id" {
  value = module.windows_servers["dc02"].instance_id
}

output "dc02_private_ip" {
  value = module.windows_servers["dc02"].private_ip
}

output "dc02_private_dns" {
  value = module.windows_servers["dc02"].private_dns
}
