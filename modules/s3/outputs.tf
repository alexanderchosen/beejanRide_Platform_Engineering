output "bucket_id" {
  value = aws_s3_bucket.my_s3_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.my_s3_bucket.arn
}

output "bucket_name" {
  value = aws_s3_bucket.my_s3_bucket.bucket
}

output "kms_key_arn" {
  value = try(aws_kms_key.kms_key[0].arn, null)
}