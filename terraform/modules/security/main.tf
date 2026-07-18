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
  ad_tcp_ports = [
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

  ad_udp_ports = [
    53,
    88,
    123,
    389,
    464
  ]
}

resource "aws_vpc_security_group_ingress_rule" "ad_tcp" {
  for_each = toset([for p in local.ad_tcp_ports : tostring(p)])

  security_group_id = aws_security_group.domain_controller.id

  ip_protocol = "tcp"

  from_port = tonumber(each.value)
  to_port   = tonumber(each.value)

  cidr_ipv4 = var.vpc_cidr
}

resource "aws_vpc_security_group_ingress_rule" "rpc_dynamic" {
  security_group_id = aws_security_group.domain_controller.id

  ip_protocol = "tcp"

  from_port = 49152
  to_port   = 65535

  cidr_ipv4 = var.vpc_cidr
}

resource "aws_vpc_security_group_ingress_rule" "ad_udp" {
  for_each = toset([for p in local.ad_udp_ports : tostring(p)])

  security_group_id = aws_security_group.domain_controller.id

  ip_protocol = "udp"

  from_port = tonumber(each.value)
  to_port   = tonumber(each.value)

  cidr_ipv4 = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.domain_controller.id

  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"
}
