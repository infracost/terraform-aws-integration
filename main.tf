terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws]
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_organizations_organization" "current" {}

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
  // Read-only actions every cross-account-link role gets, regardless of
  // whether it's installed in management or member mode.
  shared_actions = [
    // Tag fetching: fallback ListTags-style APIs for services that
    // tag:GetResources doesn't index reliably, plus the default tag API.
    "acm:ListTagsForCertificate",
    "amplify:ListApps",
    "amplify:ListTagsForResource",
    "apigateway:GET",
    "apprunner:ListServices",
    "apprunner:ListTagsForResource",
    "backup:ListTags",
    "bedrock:ListTagsForResource",
    "cloudfront:ListTagsForResource",
    "ecr:ListTagsForResource",
    "globalaccelerator:ListTagsForResource",
    "glue:GetTags",
    "logs:ListTagsForResource",
    "macie2:ListTagsForResource",
    "rds:ListTagsForResource",
    "route53:ListTagsForResource",
    "s3:GetBucketLocation",
    "s3:GetBucketTagging",
    "sagemaker:ListTags",
    "savingsplans:ListTagsForResource",
    "scheduler:ListTagsForResource",
    "sns:ListTagsForResource",
    "sqs:ListQueueTags",
    "tag:GetResources",

    // Workload discovery: enumerate workloads and surface metadata used by
    // Compute Optimizer, recommendations, and tag enrichment.
    "autoscaling:DescribeAutoScalingGroups",
    "autoscaling:DescribeAutoScalingInstances",
    "autoscaling:DescribeLaunchConfigurations",
    "cloudformation:DescribeStacks",
    "cloudformation:ListStacks",
    "ec2:DescribeInstances",
    "ec2:DescribeLaunchTemplates",
    "ec2:DescribeVolumes",
    "ecs:DescribeClusters",
    "ecs:DescribeServices",
    "ecs:DescribeTaskDefinition",
    "ecs:ListClusters",
    "ecs:ListServices",
    "ecs:ListTaskDefinitions",
    "eks:DescribeCluster",
    "eks:DescribeFargateProfile",
    "eks:DescribeNodegroup",
    "eks:ListClusters",
    "eks:ListFargateProfiles",
    "eks:ListNodegroups",
    "iam:ListInstanceProfiles",
    "iam:ListInstanceProfileTags",
    "lambda:ListFunctions",
    "lambda:ListProvisionedConcurrencyConfigs",
    "lambda:ListTags",
    "logs:DescribeLogGroups",
    "rds:DescribeDBClusters",
    "rds:DescribeDBInstances",
    "s3:ListAllMyBuckets",
  ]

  // Management-only actions: APIs that only function on the AWS
  // Organization's management account.
  management_extra_actions = [
    // BCM Data Exports — discover FOCUS / cost-allocation export configs.
    "bcm-data-exports:Get*",
    "bcm-data-exports:List*",

    // Pricing calculator scenarios.
    "bcm-pricing-calculator:*",

    // Cost Explorer.
    "ce:Describe*",
    "ce:Get*",
    "ce:List*",

    // Recommendations: Compute Optimizer, Cost Optimization Hub,
    // Trusted Advisor.
    "compute-optimizer:Get*",
    "cost-optimization-hub:Get*",
    "cost-optimization-hub:List*",
    "trustedadvisor:Describe*",
    "trustedadvisor:Get*",
    "trustedadvisor:List*",

    // Organization metadata: account list, names, tags, trusted-access
    // services.
    "organizations:DescribeOrganization",
    "organizations:ListAccounts",
    "organizations:ListAWSServiceAccessForOrganization",
    "organizations:ListTagsForResource",

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
