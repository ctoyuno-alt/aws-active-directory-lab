output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.windows.name
}

output "log_group_arn" {
  description = "CloudWatch Log Group ARN"
  value       = aws_cloudwatch_log_group.windows.arn
}

output "cloudwatch_config_parameter_name" {
  description = "SSM Parameter containing the CloudWatch Agent configuration"
  value       = aws_ssm_parameter.cloudwatch_config.name
}
