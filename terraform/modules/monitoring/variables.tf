variable "project_name" {
  description = "Project name"
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
