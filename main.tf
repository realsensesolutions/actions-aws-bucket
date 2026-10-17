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
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

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

# Preserve separately configured encryption unless the caller opts in.
# Existing adopters keep the physical encryption configuration via this move.
moved {
  from = aws_s3_bucket_server_side_encryption_configuration.bucket
  to   = aws_s3_bucket_server_side_encryption_configuration.bucket[0]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  count  = var.manage_encryption ? 1 : 0
  bucket = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "versions" {
  count      = var.noncurrent_version_expiration_days > 0 ? 1 : 0
  bucket     = aws_s3_bucket.bucket.id
  depends_on = [aws_s3_bucket_versioning.bucket_versioning]
  rule {
    id     = "ExpirePriorVersions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration { noncurrent_days = var.noncurrent_version_expiration_days }
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
  lifecycle {
    precondition {
      condition     = var.enable_versioning == "true"
      error_message = "Enable versioning before setting noncurrent_version_expiration_days."
    }
  }
}
