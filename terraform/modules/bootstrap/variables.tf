variable "bucket_name" {
  description = "Name of the S3 bucket for bootstrap artifacts"
  type        = string
}

variable "artifact_source" {
  description = "Path to the bootstrap zip artifact"
  type        = string
  default     = null
}

variable "artifact_key" {
  description = "Key for the bootstrap zip artifact in S3"
  type        = string
  default     = "bootstrap/bootstrap.zip"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
