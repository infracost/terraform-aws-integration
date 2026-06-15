output "services_monitor_arn" {
  description = "The ARN of the Cost Anomaly Detection SERVICES monitor."
  value       = aws_ce_anomaly_monitor.services.arn
}
