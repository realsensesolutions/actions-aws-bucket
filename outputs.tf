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