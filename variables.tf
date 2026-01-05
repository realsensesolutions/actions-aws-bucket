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

variable "naming_pattern" {
  description = "Bucket naming pattern: 'default' (legacy) or 'service-provider' (multi-tenant)"
  type        = string
  default     = "default"
  
  validation {
    condition     = contains(["default", "service-provider"], var.naming_pattern)
    error_message = "Naming pattern must be either 'default' or 'service-provider'."
  }
}

variable "bucket_purpose" {
  description = "Purpose suffix for bucket (e.g., 'files', 'assets', 'backups'). Only used when naming_pattern is 'service-provider'."
  type        = string
  default     = "files"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.bucket_purpose))
    error_message = "Bucket purpose must contain only lowercase letters, numbers, and hyphens."
  }
}