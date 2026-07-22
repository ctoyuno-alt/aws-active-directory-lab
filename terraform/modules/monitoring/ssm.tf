resource "aws_ssm_association" "install_cloudwatch_agent" {
  name = "AWS-ConfigureAWSPackage"

  targets {
    key    = "tag:Role"
    values = ["DomainController"]
  }

  parameters = {
    action = "Install"
    name   = "AmazonCloudWatchAgent"
  }

  wait_for_success_timeout_seconds = 600
}

resource "aws_ssm_association" "configure_cloudwatch_agent" {
  name = "AmazonCloudWatch-ManageAgent"

  depends_on = [
    aws_ssm_association.install_cloudwatch_agent
  ]

  targets {
    key    = "tag:Role"
    values = ["DomainController"]
  }

  parameters = {
    action                        = "configure"
    mode                          = "ec2"
    optionalConfigurationSource   = "ssm"
    optionalConfigurationLocation = aws_ssm_parameter.cloudwatch_config.name
    optionalRestart               = "yes"
  }

  wait_for_success_timeout_seconds = 600
}