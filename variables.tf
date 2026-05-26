variable "infracost_external_id" {
  description = "Your Infracost External ID, copied from the Infracost UI."
  type        = string
}

variable "infracost_account" {
  description = "The Infracost account ID which has permission to your account. Do not change this."
  type        = string
  default     = "237144093413"
}

variable "is_management_account" {
  description = "Whether this is the management account. If true, this sets up access to recommendations, cost, usage and pricing data. Otherwise, this sets up read-only access to a limited set of resources."
  type        = bool
  default     = false
}

variable "role_suffix" {
  description = "The suffix for the role name. This can be used if you need to create multiple roles in the same account for testing purposes."
  type        = string
  default     = ""
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs to grant access for cloud data ingestion."
  type        = list(string)
  default     = []
}

variable "enable_data_exports" {
  description = "Whether to enable billing and usage data exports provisioning."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "ARN of a KMS key to use for server-side encryption of the data export S3 buckets. If null, SSE-S3 (AES-256) is used."
  type        = string
  default     = null
}
