locals {
  name_prefix = "${var.project_name}-${var.environment}"

  endpoint_services = {
    ssm         = "com.amazonaws.ap-south-1.ssm"
    ec2messages = "com.amazonaws.ap-south-1.ec2messages"
    ssmmessages = "com.amazonaws.ap-south-1.ssmmessages"
    logs        = "com.amazonaws.ap-south-1.logs"
  }
}
