variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number

  default = 30
}

variable "tags" {
  description = "Common tags"
  type        = map(string)

  default = {}
}

variable "instance_id" {
  description = "EC2 instance ID for monitoring"
  type        = string
}

variable "alarm_cpu_threshold" {
  description = "CPU utilization threshold"
  type        = number
  default     = 80
}

variable "alarm_memory_threshold" {
  description = "Memory utilization threshold"
  type        = number
  default     = 90
}

variable "alarm_disk_free_threshold" {
  description = "Disk free percentage threshold"
  type        = number
  default     = 15
}