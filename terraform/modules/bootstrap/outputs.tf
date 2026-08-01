output "bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.bootstrap.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.bootstrap.arn
}

output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.bootstrap.bucket
}

output "bootstrap_key" {
  description = "The key of the bootstrap object in S3"
  value       = aws_s3_object.bootstrap_zip.key
}

output "bootstrap_arn" {
  description = "The ARN of the bootstrap object in S3"
  value       = aws_s3_object.bootstrap_zip.arn
}
