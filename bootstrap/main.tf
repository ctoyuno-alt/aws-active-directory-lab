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

resource "aws_s3_object" "bootstrap_zip" {
  bucket = aws_s3_bucket.bootstrap.id

  key = "bootstrap/bootstrap.zip"

  source = "${path.root}/../../../artifacts/bootstrap.zip"

  etag = filemd5("${path.root}/../../../artifacts/bootstrap.zip")
}