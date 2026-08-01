resource "aws_s3_bucket" "bootstrap" {
  bucket = var.bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "bootstrap" {
  bucket = aws_s3_bucket.bootstrap.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bootstrap" {
  bucket = aws_s3_bucket.bootstrap.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "bootstrap" {
  bucket = aws_s3_bucket.bootstrap.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

locals {
  artifact_source = coalesce(var.artifact_source, "${path.root}/../../../artifacts/bootstrap.zip")
}

resource "aws_s3_object" "bootstrap_zip" {
  bucket = aws_s3_bucket.bootstrap.id

  key    = var.artifact_key
  source = local.artifact_source

  etag = fileexists(local.artifact_source) ? filemd5(local.artifact_source) : null
}

