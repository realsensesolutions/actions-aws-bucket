variable "bucket_base_name" {
  description = "Base name for the S3 bucket"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.bucket_base_name))
    error_message = "Bucket base name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "cors_configuration" {
  description = "CORS configuration JSON content for the S3 bucket. If empty, no CORS will be configured."
  type        = string
  default     = ""
  
  validation {
    condition = var.cors_configuration == "" || can(jsondecode(var.cors_configuration))
    error_message = "CORS configuration must be valid JSON or empty string."
  }
}