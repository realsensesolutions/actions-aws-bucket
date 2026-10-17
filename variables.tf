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
    condition     = var.cors_configuration == "" || can(jsondecode(var.cors_configuration))
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

variable "enable_versioning" {
  description = "Enable versioning on the S3 bucket"
  type        = string
  default     = "false"

  validation {
    condition     = contains(["true", "false"], var.enable_versioning)
    error_message = "enable_versioning must be either 'true' or 'false'."
  }
}

variable "noncurrent_version_expiration_days" {
  description = "Expire noncurrent object versions; 0 disables expiration"
  type        = number
  default     = 0

  validation {
    condition     = var.noncurrent_version_expiration_days >= 0 && floor(var.noncurrent_version_expiration_days) == var.noncurrent_version_expiration_days
    error_message = "noncurrent_version_expiration_days must be a nonnegative integer."
  }
}

variable "force_destroy" {
  description = "Permit deletion of a nonempty bucket; disabled unless explicitly requested"
  type        = bool
  default     = false
}

variable "manage_encryption" {
  description = "Opt in to explicit S3-managed AES256 encryption; otherwise leave encryption untouched"
  type        = bool
  default     = false
}
