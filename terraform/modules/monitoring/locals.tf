locals {
  name_prefix = "${var.project_name}-${var.environment}"

  log_group_name = "/aws/ec2/windows/domain-controller"

  parameter_name = "/cloudwatch/windows/domain-controller/config"
}
