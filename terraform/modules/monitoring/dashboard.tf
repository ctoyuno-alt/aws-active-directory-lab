resource "aws_cloudwatch_dashboard" "domain_controller" {
  dashboard_name = "${var.project_name}-${var.environment}-domain-controller"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title   = "CPU Utilization"
          view    = "timeSeries"
          region  = var.aws_region
          stat    = "Average"
          period  = 300

          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              var.instance_id
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title   = "Memory Usage"
          view    = "timeSeries"
          region  = var.aws_region
          stat    = "Average"
          period  = 300

          metrics = [
            [
              "ActiveDirectoryLab",
              "Memory % Committed Bytes In Use",
              "InstanceId", var.instance_id,
              "objectname", "Memory"
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title   = "Disk Free Space"
          view    = "timeSeries"
          region  = var.aws_region
          stat    = "Average"
          period  = 300

          metrics = [
            [
              "ActiveDirectoryLab",
              "LogicalDisk % Free Space",
              "InstanceId", var.instance_id,
              "objectname", "LogicalDisk",
              "instance", "C:"
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title   = "EC2 Status Check"
          view    = "timeSeries"
          region  = var.aws_region
          stat    = "Maximum"
          period  = 60

          metrics = [
            [
              "AWS/EC2",
              "StatusCheckFailed",
              "InstanceId",
              var.instance_id
            ]
          ]
        }
      }
    ]
  })
}