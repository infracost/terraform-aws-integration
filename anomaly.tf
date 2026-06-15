resource "terraform_data" "validate_anomaly_monitors_is_management" {
  count = var.enable_anomaly_monitors ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.is_management_account
      error_message = "enable_anomaly_monitors can only be true when is_management_account is true."
    }
  }
}

module "cost_anomaly_detection" {
  count  = var.enable_anomaly_monitors ? 1 : 0
  source = "./modules/cost-anomaly-detection"

  depends_on = [terraform_data.validate_anomaly_monitors_is_management]

  tags = local.common_tags
}
