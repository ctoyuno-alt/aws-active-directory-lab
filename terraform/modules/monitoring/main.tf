resource "aws_cloudwatch_log_group" "windows" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-cloudwatch-logs"
    }
  )
}

resource "aws_ssm_parameter" "cloudwatch_config" {
  name        = local.parameter_name
  description = "CloudWatch Agent configuration for Windows Domain Controllers"
  type        = "String"

  value = file("${path.root}/../../../cloudwatch/windows-agent-config.json")

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-cloudwatch-config"
    }
  )
}
