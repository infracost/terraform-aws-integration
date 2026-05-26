variable "aws_account_id" {
  description = "The AWS account ID."
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
