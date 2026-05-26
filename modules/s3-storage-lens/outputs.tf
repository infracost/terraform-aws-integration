output "configuration_arn" {
  description = "The ARN of the S3 Storage Lens configuration."
  value       = aws_s3control_storage_lens_configuration.export.arn
}

output "bucket_arn" {
  description = "The ARN of the Storage Lens data exports S3 bucket."
  value       = aws_s3_bucket.storage_lens_data_exports.arn
}
