resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-south-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    var.private_route_table_id
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-s3-endpoint"
    }
  )
}

resource "aws_security_group" "endpoints" {
  name        = "${var.project_name}-${var.environment}-endpoints"
  description = "Security Group for Interface VPC Endpoints"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-endpoints"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.endpoints.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  cidr_ipv4 = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.endpoints.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}
