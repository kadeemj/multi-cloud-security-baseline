# A single customer-managed CMK reused across the baseline (S3 default
# encryption, CloudTrail log encryption, EBS default encryption). The key
# policy is built entirely from `var.aws_account_id` — never a live
# `data.aws_caller_identity` lookup — so this module plans with zero cloud
# credentials. The CloudTrail statement below scopes by a wildcarded trail
# ARN pattern (the standard AWS-documented approach) rather than a specific
# trail ARN, which avoids a circular dependency between this module and
# aws-logging-baseline.
data "aws_iam_policy_document" "cmk" {
  # checkov flags the root-account "kms:*"/"Resource":"*" statement below as an
  # unconstrained IAM grant (CKV_AWS_109/111/356). It is deliberately broad:
  # this is AWS's own standard, required key-administration statement for a
  # customer-managed KMS key — in a KMS *resource-based* policy the Resource
  # element only ever means "this key" regardless of its value, and every key
  # needs at least one principal with full kms:* to remain manageable via IAM.
  # Removing it risks permanently locking the key if an IAM policy elsewhere
  # is ever misconfigured.
  #checkov:skip=CKV_AWS_109:standard AWS KMS key-administration statement — Resource in a KMS resource policy always means "this key"
  #checkov:skip=CKV_AWS_111:standard AWS KMS key-administration statement — Resource in a KMS resource policy always means "this key"
  #checkov:skip=CKV_AWS_356:standard AWS KMS key-administration statement — Resource in a KMS resource policy always means "this key"
  statement {
    sid    = "EnableAccountRootPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailToEncryptLogs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:${var.aws_account_id}:trail/*"]
    }
  }

  statement {
    sid    = "AllowCloudTrailToDescribeKey"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:DescribeKey"]
    resources = ["*"]
  }
}

# CIS AWS Foundations Benchmark v3.0 §3.7-ish (illustrative) — a
# customer-managed key with rotation enabled, rather than relying solely on
# AWS-managed keys.
resource "aws_kms_key" "cmk" {
  description             = "Security baseline customer-managed key (S3, CloudTrail, EBS)."
  deletion_window_in_days = var.key_deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cmk.json
  tags                    = var.tags
}

resource "aws_kms_alias" "cmk" {
  name          = "alias/${var.key_alias}"
  target_key_id = aws_kms_key.cmk.key_id
}

# Account/region-level singleton settings — safe to plan with zero
# credentials since they don't look up any pre-existing resource.
resource "aws_ebs_encryption_by_default" "this" {
  count   = var.enable_ebs_encryption_by_default ? 1 : 0
  enabled = true
}

resource "aws_ebs_default_kms_key" "this" {
  count   = var.enable_ebs_encryption_by_default ? 1 : 0
  key_arn = aws_kms_key.cmk.arn
}
