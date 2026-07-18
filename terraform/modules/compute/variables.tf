variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "private_ip" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "instance_profile_name" {
  type = string
}

variable "root_volume_size" {
  type = number
}

variable "user_data" {
  type    = string
  default = ""
}

variable "tags" {
  type = map(string)
}

variable "key_name" {
  type    = string
  default = null
}
