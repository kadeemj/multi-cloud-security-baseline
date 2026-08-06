resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# --- Log bucket: versioned, fully blocked from public access, SSE-KMS ---

resource "aws_s3_bucket" "logs" {
  # Access logging (CKV_AWS_18), cross-region replication (CKV_AWS_144), and
  # event notifications (CKV2_AWS_62) are deliberately out of scope for this
  # curated baseline — each would require a second bucket (and, for
  # replication, a second region) purely to log/replicate a log bucket. See
  # the repo root README's "excluded by design" section.
  #checkov:skip=CKV_AWS_18:would require a second dedicated logging bucket — out of scope for the curated baseline
  #checkov:skip=CKV_AWS_144:cross-region replication of the log bucket is a resilience add-on, not a core CIS control — out of scope for the curated baseline
  #checkov:skip=CKV2_AWS_62:event notifications are an optional add-on, not a core CIS control — out of scope for the curated baseline
  bucket = "${var.bucket_name_prefix}-${random_id.bucket_suffix.hex}"
  tags   = var.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

# The bucket policy scopes to the cloudtrail.amazonaws.com service principal
# and a wildcarded trail-ARN pattern (var.aws_account_id, not this trail's own
# computed ARN) — using the real trail ARN here would create a circular
# dependency, since the trail itself must be able to validate write access to
# this bucket policy at creation time.
data "aws_iam_policy_document" "logs_bucket_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs.arn]

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:*:${var.aws_account_id}:trail/*"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/cloudtrail/AWSLogs/${var.aws_account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:*:${var.aws_account_id}:trail/*"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_bucket_policy.json
}

# --- CloudTrail: multi-region, log-file validation, KMS-encrypted ---
# CIS AWS Foundations Benchmark v3.0 §3.1 (multi-region trail), §3.2 (log
# file validation), §3.7 (CMK encryption).

resource "aws_cloudtrail" "this" {
  # An SNS topic for log-delivery notifications (CKV_AWS_252) is a
  # notification add-on, not a core CIS control — out of scope for the
  # curated baseline. CloudWatch Logs delivery + metric alarms below
  # (var.enable_cloudwatch_alarms) cover the "detect and alert" need instead.
  #checkov:skip=CKV_AWS_252:notification add-on, not a core CIS control — covered instead by the opt-in CloudWatch metric alarms below
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.logs.id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = var.kms_key_arn

  cloud_watch_logs_group_arn = var.enable_cloudwatch_alarms ? "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*" : null
  cloud_watch_logs_role_arn  = var.enable_cloudwatch_alarms ? aws_iam_role.cloudtrail_to_cloudwatch[0].arn : null

  depends_on = [aws_s3_bucket_policy.logs]

  tags = var.tags
}

# --- Optional: CloudTrail -> CloudWatch Logs + CIS-recommended metric-filter alarms ---
# Off by default (var.enable_cloudwatch_alarms). Strengthens the logging
# baseline beyond bucket delivery without needing an AWS Organization.

resource "aws_cloudwatch_log_group" "cloudtrail" {
  count             = var.enable_cloudwatch_alarms ? 1 : 0
  name              = "/security-baseline/cloudtrail/${var.trail_name}"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = var.tags
}

data "aws_iam_policy_document" "cloudtrail_to_cloudwatch_trust" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  count              = var.enable_cloudwatch_alarms ? 1 : 0
  name               = "${var.trail_name}-to-cloudwatch-logs"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_to_cloudwatch_trust[0].json
  tags               = var.tags
}

data "aws_iam_policy_document" "cloudtrail_to_cloudwatch_permissions" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"]
  }
}

resource "aws_iam_role_policy" "cloudtrail_to_cloudwatch" {
  count  = var.enable_cloudwatch_alarms ? 1 : 0
  name   = "${var.trail_name}-to-cloudwatch-logs"
  role   = aws_iam_role.cloudtrail_to_cloudwatch[0].id
  policy = data.aws_iam_policy_document.cloudtrail_to_cloudwatch_permissions[0].json
}

# CIS-recommended filter pattern: any root-account API activity that isn't
# an AWS service event and wasn't invoked on the root user's behalf.
resource "aws_cloudwatch_log_metric_filter" "root_account_usage" {
  count          = var.enable_cloudwatch_alarms ? 1 : 0
  name           = "security-baseline-root-account-usage"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"

  metric_transformation {
    name      = "RootAccountUsageCount"
    namespace = "SecurityBaseline"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_account_usage" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "security-baseline-root-account-usage"
  alarm_description   = "Triggers on any AWS root-account API activity."
  namespace           = "SecurityBaseline"
  metric_name         = "RootAccountUsageCount"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
}

# CIS-recommended filter pattern: IAM policy create/attach/detach/delete events.
resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  count          = var.enable_cloudwatch_alarms ? 1 : 0
  name           = "security-baseline-iam-policy-changes"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name
  pattern        = "{($.eventName=DeleteGroupPolicy)||($.eventName=DeleteRolePolicy)||($.eventName=DeleteUserPolicy)||($.eventName=PutGroupPolicy)||($.eventName=PutRolePolicy)||($.eventName=PutUserPolicy)||($.eventName=CreatePolicy)||($.eventName=DeletePolicy)||($.eventName=CreatePolicyVersion)||($.eventName=DeletePolicyVersion)||($.eventName=AttachRolePolicy)||($.eventName=DetachRolePolicy)||($.eventName=AttachUserPolicy)||($.eventName=DetachUserPolicy)||($.eventName=AttachGroupPolicy)||($.eventName=DetachGroupPolicy)}"

  metric_transformation {
    name      = "IAMPolicyChangeCount"
    namespace = "SecurityBaseline"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_policy_changes" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "security-baseline-iam-policy-changes"
  alarm_description   = "Triggers on IAM policy create/attach/detach/delete events."
  namespace           = "SecurityBaseline"
  metric_name         = "IAMPolicyChangeCount"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
}

# --- Optional: AWS Config recorder + delivery channel + managed rules ---
# Off by default (var.enable_aws_config) — a real running service with a
# small ongoing cost once actually applied.

data "aws_iam_policy_document" "config_trust" {
  count = var.enable_aws_config ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config" {
  count              = var.enable_aws_config ? 1 : 0
  name               = "security-baseline-config-recorder"
  assume_role_policy = data.aws_iam_policy_document.config_trust[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  count      = var.enable_aws_config ? 1 : 0
  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

data "aws_iam_policy_document" "config_bucket_permissions" {
  count = var.enable_aws_config ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/config/AWSLogs/${var.aws_account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_iam_role_policy" "config_bucket" {
  count  = var.enable_aws_config ? 1 : 0
  name   = "security-baseline-config-s3-delivery"
  role   = aws_iam_role.config[0].id
  policy = data.aws_iam_policy_document.config_bucket_permissions[0].json
}

resource "aws_config_configuration_recorder" "this" {
  count    = var.enable_aws_config ? 1 : 0
  name     = "security-baseline-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  count          = var.enable_aws_config ? 1 : 0
  name           = "security-baseline-delivery-channel"
  s3_bucket_name = aws_s3_bucket.logs.id
  s3_key_prefix  = "config"

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  count      = var.enable_aws_config ? 1 : 0
  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

resource "aws_config_config_rule" "root_account_mfa_enabled" {
  count = var.enable_aws_config ? 1 : 0
  name  = "security-baseline-root-account-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  count = var.enable_aws_config ? 1 : 0
  name  = "security-baseline-s3-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.this]
}

# --- Optional: VPC Flow Logs for an explicitly supplied VPC ---
# Off by default and never looks up "the default VPC" via a data source —
# var.vpc_id must be supplied explicitly, keeping plan credential-free.

resource "aws_flow_log" "this" {
  count                = var.enable_vpc_flow_logs ? 1 : 0
  vpc_id               = var.vpc_id
  log_destination_type = "s3"
  log_destination      = "${aws_s3_bucket.logs.arn}/vpc-flow-logs/"
  traffic_type         = "ALL"

  lifecycle {
    precondition {
      condition     = var.vpc_id != null
      error_message = "var.vpc_id must be set when enable_vpc_flow_logs is true."
    }
  }
}
