output "bucket_name" {
  description = "The name of the created S3 bucket"
  value       = aws_s3_bucket.bucket.id
}

output "bucket_arn" {
  description = "The ARN of the created S3 bucket"
  value       = aws_s3_bucket.bucket.arn
}

output "bucket_region" {
  description = "The region of the created S3 bucket"
  value       = aws_s3_bucket.bucket.region
}

output "public_url_prefix" {
  description = "HTTPS URL prefix for objects in this bucket. Empty when public_read is false."
  value       = var.public_read == "true" ? "https://${aws_s3_bucket.bucket.bucket}.s3.${aws_s3_bucket.bucket.region}.amazonaws.com/" : ""
}