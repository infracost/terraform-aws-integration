resource "terraform_data" "validate_is_management" {
  count = var.enable_data_exports ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.is_management_account
      error_message = "enable_data_exports can only be true when is_management_account is true."
    }
  }
}

module "billing_and_cost_management_export" {
  count  = var.enable_data_exports ? 1 : 0
  source = "./modules/billing-and-cost-management"

  depends_on = [terraform_data.validate_is_management]

  aws_account_id = data.aws_caller_identity.current.account_id
  kms_key_arn    = var.kms_key_arn
  tags           = local.common_tags
}

module "s3_storage_lens_export" {
  count  = var.enable_data_exports ? 1 : 0
  source = "./modules/s3-storage-lens"

  depends_on = [terraform_data.validate_is_management]

  aws_account_id         = data.aws_caller_identity.current.account_id
  aws_organization_arn   = data.aws_organizations_organization.current.arn
  aws_trusted_principals = data.aws_organizations_organization.current.aws_service_access_principals
  kms_key_arn            = var.kms_key_arn
  tags                   = local.common_tags
}
