locals {
  all_s3_bucket_arns = concat(
    var.s3_bucket_arns,
    var.enable_data_exports
    ? [
      module.billing_and_cost_management_export[0].bucket_arn,
      module.s3_storage_lens_export[0].bucket_arn
    ]
    : []
  )
}

resource "aws_iam_policy" "s3_access_policy" {
  count       = length(local.all_s3_bucket_arns) > 0 ? 1 : 0
  name        = "infracost-s3-access${var.role_suffix}"
  path        = "/"
  description = "Infracost S3 read-only policy"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "InfracostS3BucketAccess"
        Effect : "Allow"
        Action : [
          "s3:GetBucketLocation",
          "s3:ListBucket",
        ]
        Resource : local.all_s3_bucket_arns
      },
      {
        Sid : "InfracostS3ObjectAccess"
        Effect : "Allow"
        Action : [
          "s3:GetObject",
          "s3:HeadObject",
        ]
        Resource : [for arn in local.all_s3_bucket_arns : "${arn}/*"]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "s3_access_policy_attachment" {
  count      = length(local.all_s3_bucket_arns) > 0 ? 1 : 0
  policy_arn = aws_iam_policy.s3_access_policy[count.index].arn
  role       = aws_iam_role.cross_account_role.name
}
