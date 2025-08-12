# Generate random suffix for bucket name uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}

# Create S3 bucket with specified naming pattern and 63 character limit
resource "aws_s3_bucket" "bucket" {
  bucket = substr("${var.bucket_base_name}-action-aws-bucket-${random_id.suffix.hex}", 0, 63)

  tags = {
    Name        = "ActionAWSBucket"
    Environment = "GitHub-Actions"
    CreatedBy   = "realsensesolutions/actions-aws-bucket"
  }
}

# Configure bucket versioning (disabled as required)
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

# Configure bucket public access block (private as required)
resource "aws_s3_bucket_public_access_block" "bucket_pab" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configure bucket ACL (private)
resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.bucket_acl_ownership]
  
  bucket     = aws_s3_bucket.bucket.id
  acl        = "private"
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