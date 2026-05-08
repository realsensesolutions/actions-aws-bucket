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

output "bucket_url" {
  description = "Public HTTPS base URL for the bucket (https://<bucket>.s3.<region>.amazonaws.com)"
  value       = "https://${aws_s3_bucket.bucket.bucket}.s3.${aws_s3_bucket.bucket.region}.amazonaws.com"
}