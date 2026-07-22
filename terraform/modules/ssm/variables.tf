variable "domain_admin_username" {
  type = string
}

variable "domain_admin_password" {
  type      = string
  sensitive = true
}