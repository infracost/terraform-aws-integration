output "account_id" {
  description = "The AWS account ID where the module was provisioned."
  value       = data.aws_caller_identity.current.account_id
}

output "account_region" {
  description = "The AWS region of the account where the module was provisioned."
  value       = data.aws_region.current.region
}

output "role_arn" {
  description = "The ARN value of the Cross-Account Role with IAM read-only permissions. Provide this to Infracost."
  value       = aws_iam_role.cross_account_role.arn
}

output "billing_and_cost_management_export_arn" {
  description = "The ARN of the BCM Data Exports export."
  value       = var.enable_data_exports ? module.billing_and_cost_management_export[0].export_arn : null
}

output "billing_and_cost_management_bucket_arn" {
  description = "The ARN of the S3 bucket used for BCM Data Exports."
  value       = var.enable_data_exports ? module.billing_and_cost_management_export[0].bucket_arn : null
}

output "s3_storage_lens_configuration_arn" {
  description = "The ARN of the S3 Storage Lens configuration."
  value       = var.enable_data_exports ? module.s3_storage_lens_export[0].configuration_arn : null
}

output "s3_storage_lens_bucket_arn" {
  description = "The ARN of the S3 bucket used for S3 Storage Lens exports."
  value       = var.enable_data_exports ? module.s3_storage_lens_export[0].bucket_arn : null
}
