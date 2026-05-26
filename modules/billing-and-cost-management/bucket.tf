resource "aws_s3_bucket" "bcm_data_exports" {
  bucket = "infracost-bcm-exports-${var.aws_account_id}"
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "bcm_data_exports" {
  bucket                  = aws_s3_bucket.bcm_data_exports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bcm_data_exports" {
  count  = var.kms_key_arn != null ? 1 : 0
  bucket = aws_s3_bucket.bcm_data_exports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "data_exports_lifecycle" {
  bucket = aws_s3_bucket.bcm_data_exports.id

  rule {
    id     = "intelligent-tiering"
    status = "Enabled"

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "data_exports_policy_doc" {
  statement {
    sid    = "AllowBCMDataExportsWrite"
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "bcm-data-exports.amazonaws.com",
        "billingreports.amazonaws.com",
      ]
    }

    actions = [
      "s3:GetBucketPolicy",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.bcm_data_exports.arn,
      "${aws_s3_bucket.bcm_data_exports.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        var.aws_account_id,
      ]
    }
  }

  statement {
    sid    = "DenyNonSSLRequests"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.bcm_data_exports.arn,
      "${aws_s3_bucket.bcm_data_exports.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "data_exports_policy" {
  bucket = aws_s3_bucket.bcm_data_exports.id
  policy = data.aws_iam_policy_document.data_exports_policy_doc.json
}
