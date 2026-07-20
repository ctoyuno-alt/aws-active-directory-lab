output "endpoint_security_group_id" {
  description = "Security Group used by Interface VPC Endpoints"
  value       = aws_security_group.endpoints.id
}
