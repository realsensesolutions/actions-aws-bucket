variable "bucket_base_name" {
  description = "Base name for the S3 bucket"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.bucket_base_name))
    error_message = "Bucket base name must contain only lowercase letters, numbers, and hyphens."
  }
}