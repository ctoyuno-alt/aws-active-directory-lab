output "terraform_state_bucket" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "terraform_lock_table" {
  value = aws_dynamodb_table.terraform_lock.name
}

output "bucket_name" {
  value = aws_s3_bucket.bootstrap.bucket
}

output "bootstrap_key" {
  value = aws_s3_object.bootstrap_zip.key
}