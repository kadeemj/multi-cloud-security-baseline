# CIS AWS Foundations Benchmark v3.0 §1.9, 1.10, 1.11 — enforce a strong,
# account-wide IAM password policy instead of leaving AWS defaults in place.
resource "aws_iam_account_password_policy" "this" {
  minimum_password_length        = var.password_policy_minimum_length
  password_reuse_prevention      = var.password_policy_reuse_prevention
  max_password_age               = var.password_policy_max_age
  require_symbols                = var.password_policy_require_symbols
  require_numbers                = var.password_policy_require_numbers
  require_uppercase_characters   = var.password_policy_require_uppercase
  require_lowercase_characters   = var.password_policy_require_lowercase
  allow_users_to_change_password = true
}

# Demonstrates the least-privilege pattern this baseline expects: scoped
# actions instead of "Action": "*". All actions below are read-only,
# account-metadata operations that AWS IAM does not support scoping to a
# specific resource ARN for (they only support "Resource": "*" per the AWS
# IAM Actions/Resources/Condition Keys reference) — the checkov skip below is
# a deliberate, justified exception, not a suppressed real finding.
data "aws_iam_policy_document" "example_readonly_auditor" {
  #checkov:skip=CKV_AWS_356:iam/cloudtrail/config list & describe actions here have no resource-level ARN to scope to; AWS IAM only supports "Resource":"*" for them
  statement {
    sid    = "ReadOnlySecurityAudit"
    effect = "Allow"
    actions = [
      "iam:GetAccountPasswordPolicy",
      "iam:GetAccountSummary",
      "iam:ListUsers",
      "iam:ListRoles",
      "cloudtrail:DescribeTrails",
      "cloudtrail:GetTrailStatus",
      "config:DescribeConfigRules",
      "config:DescribeComplianceByConfigRule",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "example_readonly_auditor" {
  name        = "${var.example_role_name}-policy"
  description = "Least-privilege, read-only security-audit policy — the pattern to follow instead of attaching AdministratorAccess or wildcard policies."
  policy      = data.aws_iam_policy_document.example_readonly_auditor.json
  tags        = var.tags
}

data "aws_iam_policy_document" "example_readonly_auditor_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "example_readonly_auditor" {
  name               = var.example_role_name
  assume_role_policy = data.aws_iam_policy_document.example_readonly_auditor_trust.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "example_readonly_auditor" {
  role       = aws_iam_role.example_readonly_auditor.name
  policy_arn = aws_iam_policy.example_readonly_auditor.arn
}
