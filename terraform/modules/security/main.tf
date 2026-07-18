resource "aws_security_group" "domain_controller" {
  name        = "${var.project_name}-${var.environment}-dc"
  description = "Security Group for Domain Controllers"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-dc"
    }
  )
}

locals {
  ad_ports = [
    53,
    88,
    135,
    389,
    445,
    464,
    636,
    3268,
    3269,
    9389
  ]
}

resource "aws_vpc_security_group_ingress_rule" "ad_tcp" {
  for_each = toset(local.ad_ports)

  security_group_id = aws_security_group.domain_controller.id

  ip_protocol = "tcp"

  from_port = each.value
  to_port   = each.value

  cidr_ipv4 = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.domain_controller.id

  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"
}
