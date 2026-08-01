variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "bootstrap_arn" {
  description = "ARN of the bootstrap artifact S3 object"
  type        = string
}

variable "tags" {
  type = map(string)
}

