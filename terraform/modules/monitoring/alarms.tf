resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-dc-cpu-high"
  alarm_description   = "High CPU utilization on Domain Controller"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  statistic   = "Average"
  period      = 300

  threshold = var.alarm_cpu_threshold

  dimensions = {
    InstanceId = var.instance_id
  }

  treat_missing_data = "notBreaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.project_name}-${var.environment}-dc-memory-high"
  alarm_description   = "High memory utilization on Domain Controller"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  namespace   = "ActiveDirectoryLab"
  metric_name = "Memory % Committed Bytes In Use"

  statistic = "Average"
  period    = 300

  threshold = var.alarm_memory_threshold

  dimensions = {
    InstanceId = var.instance_id
    objectname = "Memory"
  }

  treat_missing_data = "notBreaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "disk_low" {
  alarm_name        = "${var.project_name}-${var.environment}-dc-disk-low"
  alarm_description = "Low disk free space on Domain Controller"

  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  namespace   = "ActiveDirectoryLab"
  metric_name = "LogicalDisk % Free Space"

  statistic = "Average"
  period    = 300

  threshold = var.alarm_disk_free_threshold

  dimensions = {
    InstanceId = var.instance_id
    objectname = "LogicalDisk"
    instance   = "C:"
  }

  treat_missing_data = "notBreaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  alarm_name        = "${var.project_name}-${var.environment}-dc-status-check"
  alarm_description = "EC2 status check failure"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1

  namespace   = "AWS/EC2"
  metric_name = "StatusCheckFailed"

  statistic = "Maximum"
  period    = 60

  threshold = 1

  dimensions = {
    InstanceId = var.instance_id
  }

  treat_missing_data = "notBreaching"

  tags = var.tags
}