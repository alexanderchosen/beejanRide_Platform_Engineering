# for me to create a standard s3 storage with the necessary capabilities, security and defaults,
# I need to create a bucket + encryption + versioning + public-access block option + lifecycle rules

# also, because s3 buckets have to be unique globally,i plan to attach a random suffix to the end of the name just to ensure that all buckets have unique names

resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  bucket_name = lower("${var.name_prefix}-${var.purpose}-${random_id.suffix.hex}")

  default_lifecycle_days = {
    public    = 90
    internal  = 180
    sensitive = 365
  }
  lifecycle_days = coalesce(var.lifecycle_days, local.default_lifecycle_days[var.data_classification])

  sse_algorithm = var.data_classification == "sensitive" ? "aws:kms" : "AES256"
}

# using the KMS key is not free, so it will just be here for demo
resource "aws_kms_key" "kms_key" {
  count = var.data_classification == "sensitive" ? 1 : 0
  enable_key_rotation = true
}

resource "aws_s3_bucket" "my_s3_bucket" {
  bucket = local.bucket_name
  force_destroy = true

  tags = {
    Name  = local.bucket_name
    DataClassification = var.data_classification
  }
}

resource "aws_s3_bucket_versioning" "bucket_version" {
  bucket = aws_s3_bucket.my_s3_bucket.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "server_encrypt" {
  bucket = aws_s3_bucket.my_s3_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = local.sse_algorithm
      kms_master_key_id = var.data_classification == "sensitive" ? aws_kms_key.kms_key[0].arn : null
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.my_s3_bucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_config" {
  bucket = aws_s3_bucket.my_s3_bucket.id
  rule {
    id = "expire-objects"
    status = "Enabled"
    expiration {
      days = local.lifecycle_days
    }
  }
}

resource "aws_s3_bucket_policy" "deny_insecure_transport" {
  bucket = aws_s3_bucket.my_s3_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid = "DenyInsecureTransport"
      Effect = "Deny"
      Principal = "*"
      Action = "s3:*"
      Resource  = [aws_s3_bucket.my_s3_bucket.arn, "${aws_s3_bucket.my_s3_bucket.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}