# Generate random suffix for bucket name uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for bucket naming
locals {
  # Legacy naming: ${name}-action-aws-bucket-${random_id}
  # Multi-tenant naming: ${name}-${purpose}-${random_id}
  bucket_name = var.naming_pattern == "service-provider" ? (
    substr("${var.bucket_base_name}-${var.bucket_purpose}-${random_id.suffix.hex}", 0, 63)
    ) : (
    substr("${var.bucket_base_name}-action-aws-bucket-${random_id.suffix.hex}", 0, 63)
  )
}

# Create S3 bucket with specified naming pattern and 63 character limit
resource "aws_s3_bucket" "bucket" {
  bucket = local.bucket_name

  tags = {
    Name        = "ActionAWSBucket"
    Environment = "GitHub-Actions"
    CreatedBy   = "realsensesolutions/actions-aws-bucket"
  }
}

# Configure bucket versioning (disabled by default, can be enabled via enable_versioning)
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.enable_versioning == "true" ? "Enabled" : "Disabled"
  }
}

# Configure bucket public access block (driven by var.public)
resource "aws_s3_bucket_public_access_block" "bucket_pab" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = var.public == "true" ? false : true
  block_public_policy     = var.public == "true" ? false : true
  ignore_public_acls      = var.public == "true" ? false : true
  restrict_public_buckets = var.public == "true" ? false : true
}

# Public-read bucket policy (only when var.public == "true")
resource "aws_s3_bucket_policy" "public_read" {
  count  = var.public == "true" ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.bucket_pab]
}

# Configure bucket ACL (private)
resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.bucket_acl_ownership]

  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

# Configure bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "bucket_acl_ownership" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Configure CORS (conditional - only if cors_configuration is provided)
resource "aws_s3_bucket_cors_configuration" "bucket_cors" {
  count  = var.cors_configuration != "" ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  dynamic "cors_rule" {
    for_each = try(jsondecode(var.cors_configuration), [])
    content {
      allowed_headers = try(cors_rule.value.AllowedHeaders, [])
      allowed_methods = cors_rule.value.AllowedMethods
      allowed_origins = cors_rule.value.AllowedOrigins
      expose_headers  = try(cors_rule.value.ExposeHeaders, [])
      max_age_seconds = try(cors_rule.value.MaxAgeSeconds, null)
    }
  }
}