variable "aws_organization_arn" {
  description = "The ARN of the AWS Organization for Storage Lens configuration scope."
  type        = string
}

variable "aws_trusted_principals" {
  description = "The list of trusted principals for organization wide visibility."
  type        = list(string)
}

variable "aws_account_id" {
  description = "The AWS account ID for the Storage Lens configuration."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "ARN of a KMS key to use for server-side encryption of the S3 bucket. If null, SSE-S3 (AES-256) is used."
  type        = string
  default     = null
}

variable "enable_advanced_metrics" {
  description = "Enable S3 Storage Lens advanced-tier metrics (activity_metrics and advanced_cost_optimization_metrics) at the account and bucket level. Both are advanced-tier features billed per million objects monitored org-wide; set to false to stay on the free metrics tier."
  type        = bool
  default     = true
}
