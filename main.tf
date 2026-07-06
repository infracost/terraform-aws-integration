terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws]
    }
  }
}

data "aws_caller_identity" "current" {}

# Only read organization metadata when data exports are enabled on a
# management account — the only path that consumes the result. Gating on
# both flags avoids requiring organizations:DescribeOrganization on
# member-account installs, and ensures a misconfigured member-account caller
# (enable_data_exports = true, is_management_account = false) hits the
# friendly precondition in exports.tf instead of an Organizations API error.
data "aws_organizations_organization" "current" {
  count = var.is_management_account && var.enable_data_exports ? 1 : 0
}

locals {
  common_tags = {
    InfracostModuleVersion = local.module_version
  }
}

resource "aws_iam_role" "cross_account_role" {
  name = "infracost-readonly${var.role_suffix}"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement = [
      {
        Effect : "Allow", Principal : { AWS : "arn:aws:iam::${var.infracost_account}:root" }, Action : "sts:AssumeRole",
        Condition : { StringEquals : { "sts:ExternalId" : var.infracost_external_id } }
      }
    ]
  })

  tags = local.common_tags
}

locals {
  // ViewOnlyAccess managed policy, attached to every cross account role
  // below. It already grants the bulk of the read-only resource-discovery
  // and per-service ListTags/Describe APIs, so the inline actions here are
  // deliberately limited to what ViewOnlyAccess does NOT cover, plus a few
  // wildcards that are intentionally broader than ViewOnlyAccess grants.
  // see: https://docs.aws.amazon.com/aws-managed-policy/latest/reference/ViewOnlyAccess.html
  view_only_access_policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"

  // Read-only actions every cross-account-link role gets, regardless of
  // whether it's installed in management or member mode. These are NOT
  // covered by the ViewOnlyAccess managed policy.
  shared_actions = [
    // Tag fetching: fallback ListTags-style APIs for services that
    // tag:GetResources doesn't index reliably, plus the default tag API.
    // ViewOnlyAccess has no `tag:` service and only a subset of these
    // per-service tag APIs.
    "acm:ListTagsForCertificate",
    "amplify:ListApps",
    "amplify:ListTagsForResource",
    "apigateway:GET",
    "apprunner:ListServices",
    "apprunner:ListTagsForResource",
    "ecr:ListTagsForResource",
    "globalaccelerator:ListTagsForResource",
    "macie2:ListTagsForResource",
    "rds:ListTagsForResource",
    "s3:GetBucketLocation",
    "s3:GetBucketTagging",
    "savingsplans:ListTagsForResource",
    "scheduler:ListTagsForResource",
    "tag:GetResources",

    // Resource config for IaC attribution: memory/storage of Lambda functions.
    // ViewOnlyAccess grants only lambda:List*, not GetFunctionConfiguration.
    "lambda:GetFunctionConfiguration",

    // Workload discovery not covered by ViewOnlyAccess (no DescribeLaunch*
    // wildcard).
    "ec2:DescribeLaunchTemplates",

    // ViewOnlyAccess enumerates EC2 describes individually; these two aren't in it.
    "ec2:DescribeClientVpnEndpoints",
    "ec2:DescribeTransitGatewayAttachments",
  ]

  // Management-only actions: APIs that only function on the AWS
  // Organization's management account. None of the cost/pricing APIs are
  // part of ViewOnlyAccess, which is resource-view-only.
  management_extra_actions = [
    // BCM Data Exports — discover FOCUS / cost-allocation export configs.
    "bcm-data-exports:Get*",
    "bcm-data-exports:List*",

    // Cost Explorer.
    "ce:Describe*",
    "ce:Get*",
    "ce:List*",

    // Recommendations: Compute Optimizer, Cost Optimization Hub,
    // Trusted Advisor. The cost-optimization-hub and trustedadvisor
    // Get*/List* wildcards are intentionally broader than the specific
    // actions ViewOnlyAccess grants.
    "compute-optimizer:Get*",
    "cost-optimization-hub:Get*",
    "cost-optimization-hub:List*",
    "trustedadvisor:Get*",
    "trustedadvisor:List*",

    // Organization metadata: ListAccounts/ListTagsForResource etc. come
    // from ViewOnlyAccess (organizations:List*); DescribeOrganization does
    // not.
    "organizations:DescribeOrganization",

    // Pricing API.
    "pricing:Describe*",
    "pricing:Get*",
    "pricing:List*",

    // S3 Storage Lens configuration discovery.
    "s3:GetStorageLensConfiguration",
    "s3:GetStorageLensConfigurationTagging",
    "s3:GetStorageLensDashboard",
    "s3:ListStorageLensConfigurations",
  ]
}

resource "aws_iam_role_policy_attachment" "view_only_access_attachment" {
  policy_arn = local.view_only_access_policy_arn
  role       = aws_iam_role.cross_account_role.name
}

resource "aws_iam_policy" "management_account_readonly_policy" {
  count       = var.is_management_account ? 1 : 0
  name        = "infracost-management-account-readonly${var.role_suffix}"
  path        = "/"
  description = "Infracost management account read-only policy"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : sort(concat(local.shared_actions, local.management_extra_actions)),
        Resource : "*",
        Effect : "Allow",
        Sid : "InfracostManagementAccountReadOnly"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "management_account_readonly_policy_attachment" {
  count      = var.is_management_account ? 1 : 0
  policy_arn = aws_iam_policy.management_account_readonly_policy[count.index].arn
  role       = aws_iam_role.cross_account_role.name
}

resource "aws_iam_policy" "member_account_readonly_policy" {
  count       = var.is_management_account ? 0 : 1
  name        = "infracost-member-account-readonly${var.role_suffix}"
  path        = "/"
  description = "Infracost member account read-only policy"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : sort(local.shared_actions),
        Resource : "*",
        Effect : "Allow",
        Sid : "InfracostMemberAccountReadOnly"
      }
    ]
  })

  tags = local.common_tags
}

# Attach policies to the role
resource "aws_iam_role_policy_attachment" "member_account_readonly_policy_attachment" {
  count      = var.is_management_account ? 0 : 1
  policy_arn = aws_iam_policy.member_account_readonly_policy[count.index].arn
  role       = aws_iam_role.cross_account_role.name
}

resource "aws_iam_policy" "role_introspection_policy" {
  name        = "infracost-role-introspection${var.role_suffix}"
  path        = "/"
  description = "Allows the Infracost cross-account role to read and simulate its own permissions for feature detection"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "InspectRole",
        Effect : "Allow",
        Action : [
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:SimulatePrincipalPolicy",
        ],
        Resource : aws_iam_role.cross_account_role.arn,
      },
      {
        Sid : "InspectAttachedPolicies",
        Effect : "Allow",
        Action : [
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
        ],
        Resource : "*",
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "role_introspection_policy_attachment" {
  policy_arn = aws_iam_policy.role_introspection_policy.arn
  role       = aws_iam_role.cross_account_role.name
}

resource "aws_iam_policy" "kms_decrypt_policy" {
  count       = var.is_management_account && var.kms_key_arn != null ? 1 : 0
  name        = "infracost-kms-decrypt${var.role_suffix}"
  path        = "/"
  description = "Allows the Infracost cross-account role to decrypt S3 export objects using the customer-managed KMS key"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "InfracostKMSDecrypt",
        Effect : "Allow",
        Action : [
          "kms:Decrypt",
          "kms:DescribeKey",
        ],
        Resource : var.kms_key_arn,
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "kms_decrypt_policy_attachment" {
  count      = var.is_management_account && var.kms_key_arn != null ? 1 : 0
  policy_arn = aws_iam_policy.kms_decrypt_policy[0].arn
  role       = aws_iam_role.cross_account_role.name
}
