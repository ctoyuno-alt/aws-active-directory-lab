locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sahil"
  }

  windows_servers = {
    dc01 = {
      hostname         = "DC01"
      role             = "DomainController"
      subnet_id        = module.networking.private_subnet_a_id
      private_ip       = var.dc01_private_ip
      instance_type    = var.dc01_instance_type
      root_volume_size = var.dc01_root_volume_size
      user_data        = file("${path.root}/../../../userdata/windows/windows-bootstrap.ps1")
    }

    dc02 = {
      hostname         = "DC02"
      role             = "DomainController"
      subnet_id        = module.networking.private_subnet_b_id
      private_ip       = var.dc02_private_ip
      instance_type    = var.dc02_instance_type
      root_volume_size = var.dc02_root_volume_size
      user_data        = file("${path.root}/../../../userdata/windows/join-dc02.ps1")
    }

    fs01 = {
      hostname         = "FS01"
      role             = "FileServer"
      subnet_id        = module.networking.private_subnet_b_id
      private_ip       = var.fs01_private_ip
      instance_type    = var.fs01_instance_type
      root_volume_size = var.fs01_root_volume_size
      user_data        = file("${path.root}/../../../userdata/windows/join-fs01.ps1")
    }
  }
}
