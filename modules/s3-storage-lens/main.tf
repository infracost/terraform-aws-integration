# Requires trusted access to be configured for cross account visibility.
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage_lens_with_organizations_enabling_trusted_access.html
resource "terraform_data" "validate_trusted_access" {
  lifecycle {
    precondition {
      condition     = contains(var.aws_trusted_principals, "storage-lens.s3.amazonaws.com")
      error_message = "S3 Storage Lens must have trusted access configured for cross-account visibility: https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage_lens_with_organizations_enabling_trusted_access.html"
    }
  }
}

resource "aws_s3control_storage_lens_configuration" "export" {
  depends_on = [terraform_data.validate_trusted_access]
  config_id  = "InfracostStorageLensExport"

  storage_lens_configuration {
    enabled = true

    account_level {
      activity_metrics {
        enabled = true
      }

      advanced_cost_optimization_metrics {
        enabled = true
      }

      # https://github.com/hashicorp/terraform-provider-aws/issues/46851
      # advanced_performance_metrics {
      #   enabled = true
      # }

      bucket_level {
        activity_metrics {
          enabled = true
        }

        advanced_cost_optimization_metrics {
          enabled = true
        }

        # https://github.com/hashicorp/terraform-provider-aws/issues/46851
        # advanced_performance_metrics {
        #   enabled = true
        # }
      }
    }

    aws_org {
      arn = var.aws_organization_arn
    }

    data_export {
      s3_bucket_destination {
        account_id            = var.aws_account_id
        arn                   = aws_s3_bucket.storage_lens_data_exports.arn
        prefix                = ""
        format                = "Parquet"
        output_schema_version = "V_1"
      }
    }
  }

  tags = var.tags
}
