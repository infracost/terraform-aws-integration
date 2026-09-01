// A separate role to keep infracost-readonly read-only.
resource "aws_iam_role" "bedrock_role" {
  count              = var.enable_bedrock_invoke ? 1 : 0
  name               = "infracost-bedrock${var.role_suffix}"
  assume_role_policy = local.infracost_trust_policy

  tags = local.common_tags
}

locals {
  // Regions use wildcards because cross-region profiles need access to
  // models in every region they use.
  bedrock_vendor_model_arns = {
    anthropic = [
      "arn:aws:bedrock:*::foundation-model/anthropic.*",
      "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/*.anthropic.*",
    ]
  }

  // Application profile IDs hide their models, but access still follows
  // the vendor limits above.
  bedrock_model_arns = concat(
    flatten([for v in toset(var.bedrock_model_vendors) : local.bedrock_vendor_model_arns[v]]),
    ["arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:application-inference-profile/*"],
  )
}

resource "aws_iam_policy" "bedrock_invoke_policy" {
  count       = var.enable_bedrock_invoke ? 1 : 0
  name        = "infracost-bedrock-invoke${var.role_suffix}"
  path        = "/"
  description = "Lets the Infracost Bedrock role invoke models from the configured vendors and read model availability in this account"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "InfracostBedrockInvoke",
        Effect : "Allow",
        Action : [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
        ],
        Resource : local.bedrock_model_arns
      },
      {
        // Read-only checks so setup problems can be reported clearly:
        // which inference profiles exist and whether model access is
        // enabled.
        Sid : "InfracostBedrockInspect",
        Effect : "Allow",
        Action : [
          "bedrock:GetFoundationModelAvailability",
          "bedrock:GetInferenceProfile",
          "bedrock:ListFoundationModels",
          "bedrock:ListInferenceProfiles",
        ],
        Resource : "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "bedrock_invoke_policy_attachment" {
  count      = var.enable_bedrock_invoke ? 1 : 0
  policy_arn = aws_iam_policy.bedrock_invoke_policy[count.index].arn
  role       = aws_iam_role.bedrock_role[count.index].name
}
