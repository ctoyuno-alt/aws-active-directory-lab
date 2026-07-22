resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  private_ip             = var.private_ip
  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile = var.instance_profile_name

  key_name = var.key_name

  user_data = var.user_data

  monitoring = true

  disable_api_termination = true

  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(
  var.tags,
  {
    Name = "${var.project_name}-${var.environment}-${lower(var.hostname)}"
    Role = var.role
  }
)

  lifecycle {
    prevent_destroy = true
  }
}

