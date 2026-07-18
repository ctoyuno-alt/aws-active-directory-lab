output "vpc_id" {
  value = module.networking.vpc_id
}
output "instance_profile_name" {
  value = module.identity.instance_profile_name
}
output "domain_controller_sg_id" {
  value = module.security.domain_controller_sg_id
}
