resource "aws_ssm_association" "install_cloudwatch_agent" {
  name = "AWS-ConfigureAWSPackage"

  targets {
    key    = "InstanceIds"
    values = [var.instance_id]
  }

  parameters = {
    action = "Install"
    name   = "AmazonCloudWatchAgent"
  }

  wait_for_success_timeout_seconds = 600
}