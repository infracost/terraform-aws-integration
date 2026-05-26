output "export_arn" {
  description = "The ARN of the BCM Data Exports export."
  value       = aws_bcmdataexports_export.daily_focus.export[0].export_arn
}

output "bucket_arn" {
  description = "The ARN of the BCM data exports S3 bucket."
  value       = aws_s3_bucket.bcm_data_exports.arn
}
