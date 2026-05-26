locals {
  # https://focus.finops.org/focus-specification/v1-2/
  focus_1_2_columns = [
    "AvailabilityZone",
    "BilledCost",
    "BillingAccountId",
    "BillingAccountName",
    "BillingAccountType",
    "BillingCurrency",
    "BillingPeriodEnd",
    "BillingPeriodStart",
    "CapacityReservationId",
    "CapacityReservationStatus",
    "ChargeCategory",
    "ChargeClass",
    "ChargeDescription",
    "ChargeFrequency",
    "ChargePeriodEnd",
    "ChargePeriodStart",
    "CommitmentDiscountCategory",
    "CommitmentDiscountId",
    "CommitmentDiscountName",
    "CommitmentDiscountQuantity",
    "CommitmentDiscountType",
    "CommitmentDiscountStatus",
    "CommitmentDiscountUnit",
    "ConsumedQuantity",
    "ConsumedUnit",
    "ContractedCost",
    "ContractedUnitPrice",
    "EffectiveCost",
    "InvoiceId",
    "InvoiceIssuerName",
    "ListCost",
    "ListUnitPrice",
    "PricingCategory",
    "PricingCurrency",
    "PricingCurrencyContractedUnitPrice",
    "PricingCurrencyEffectiveCost",
    "PricingCurrencyListUnitPrice",
    "PricingQuantity",
    "PricingUnit",
    "ProviderName",
    "PublisherName",
    "RegionId",
    "RegionName",
    "ResourceId",
    "ResourceName",
    "ResourceType",
    "ServiceCategory",
    "ServiceName",
    "ServiceSubcategory",
    "SkuId",
    "SkuPriceDetails",
    "SkuPriceId",
    "SkuMeter",
    "SubAccountId",
    "SubAccountName",
    "SubAccountType",
    "Tags",
    "x_Discounts",
    "x_Operation",
    "x_ServiceCode",
  ]
}

locals {
  # https://docs.aws.amazon.com/cur/latest/userguide/dataexports-create-standard.html
  cost_optimization_columns = [
    "account_id",
    "account_name",
    "recommendation_id",
    "resource_arn",
    "region",
    "current_resource_type",
    "recommended_resource_type",
    "action_type",
    "current_resource_summary",
    "recommended_resource_summary",
    "estimated_monthly_cost_before_discount",
    "estimated_monthly_cost_after_discount",
    "estimated_monthly_savings_before_discount",
    "estimated_monthly_savings_after_discount",
    "estimated_savings_percentage_before_discount",
    "estimated_savings_percentage_after_discount",
    "currency_code",
    "restart_needed",
    "rollback_possible",
    "implementation_effort",
    "tags",
    "current_resource_details",
    "recommended_resource_details",
    "recommendation_source",
    "recommendation_lookback_period_in_days",
    "last_refresh_timestamp",
  ]
}

resource "aws_iam_service_linked_role" "bcm_data_exports" {
  aws_service_name = "bcm-data-exports.amazonaws.com"
}

resource "aws_bcmdataexports_export" "daily_cost_optimization" {
  depends_on = [aws_iam_service_linked_role.bcm_data_exports]

  export {
    name = "InfracostDailyCostOptimizationExport"

    data_query {
      query_statement = format("SELECT %s FROM COST_OPTIMIZATION_RECOMMENDATIONS", join(", ", local.cost_optimization_columns))
      table_configurations = {
        "COST_OPTIMIZATION_RECOMMENDATIONS" = {
          "INCLUDE_ALL_RECOMMENDATIONS" = "TRUE"
          "FILTER"                      = "{}"
        }
      }
    }

    destination_configurations {
      s3_destination {
        s3_region = aws_s3_bucket.bcm_data_exports.region
        s3_bucket = aws_s3_bucket.bcm_data_exports.id
        s3_prefix = ""

        s3_output_configurations {
          overwrite   = "OVERWRITE_REPORT"
          format      = "PARQUET"
          compression = "PARQUET"
          output_type = "CUSTOM"
        }
      }
    }

    refresh_cadence {
      frequency = "SYNCHRONOUS"
    }
  }

  tags = var.tags
}

resource "aws_bcmdataexports_export" "daily_focus" {
  export {
    name = "InfracostDailyFocusExport"

    data_query {
      query_statement = format("SELECT %s FROM FOCUS_1_2_AWS", join(", ", local.focus_1_2_columns))
      table_configurations = {
        "FOCUS_1_2_AWS" = {
          "TIME_GRANULARITY" = "DAILY"
        }
      }
    }

    destination_configurations {
      s3_destination {
        s3_region = aws_s3_bucket.bcm_data_exports.region
        s3_bucket = aws_s3_bucket.bcm_data_exports.id
        s3_prefix = ""

        s3_output_configurations {
          overwrite   = "OVERWRITE_REPORT"
          format      = "PARQUET"
          compression = "PARQUET"
          output_type = "CUSTOM"
        }
      }
    }

    refresh_cadence {
      frequency = "SYNCHRONOUS"
    }
  }

  tags = var.tags
}
