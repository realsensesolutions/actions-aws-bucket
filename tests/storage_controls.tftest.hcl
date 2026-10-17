mock_provider "aws" {}
mock_provider "random" {}

variables { bucket_base_name = "example-assets" }

run "existing_defaults" {
  command = plan
  assert {
    condition     = aws_s3_bucket.bucket.force_destroy == false && aws_s3_bucket_versioning.bucket_versioning.versioning_configuration[0].status == "Disabled"
    error_message = "Existing callers must not enable versioning or force deletion."
  }
  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.versions) == 0
    error_message = "Previous versions must not expire unless explicitly configured."
  }
  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.bucket) == 0
    error_message = "Default behavior must not change separately configured encryption."
  }
}

run "production_versions" {
  command = plan
  variables {
    enable_versioning                  = "true"
    noncurrent_version_expiration_days = 30
    manage_encryption                  = true
  }
  assert {
    condition     = aws_s3_bucket_versioning.bucket_versioning.versioning_configuration[0].status == "Enabled" && aws_s3_bucket.bucket.force_destroy == false
    error_message = "Versioned production storage must protect nonempty buckets."
  }
  assert {
    condition     = one(aws_s3_bucket_lifecycle_configuration.versions[0].rule).noncurrent_version_expiration[0].noncurrent_days == 30
    error_message = "Only prior object versions should expire after 30 days."
  }
  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.bucket) == 1 && one(aws_s3_bucket_server_side_encryption_configuration.bucket[0].rule).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Explicit opt-in must manage S3 AES256 encryption."
  }
}

run "reject_expiration_without_versioning" {
  command = plan
  variables { noncurrent_version_expiration_days = 30 }
  expect_failures = [aws_s3_bucket_lifecycle_configuration.versions]
}

run "reject_invalid_expiration" {
  command = plan
  variables { noncurrent_version_expiration_days = -1 }
  expect_failures = [var.noncurrent_version_expiration_days]
}

run "explicit_disposable_bucket" {
  command = plan
  variables { force_destroy = true }
  assert {
    condition     = aws_s3_bucket.bucket.force_destroy == true
    error_message = "Force deletion is allowed only when the caller explicitly opts in."
  }
}
