resource "aws_ce_anomaly_monitor" "services" {
  name              = "InfracostServicesMonitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = var.tags
}
