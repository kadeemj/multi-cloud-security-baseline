variable "aws_account_id" {
  description = "AWS account ID used to scope the CloudTrail bucket policy's aws:SourceArn condition. Passed explicitly (never looked up via data.aws_caller_identity) so this module can plan with zero cloud credentials."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the customer-managed KMS key (from aws-encryption-baseline) used to encrypt the CloudTrail bucket and trail."
  type        = string
}

variable "trail_name" {
  description = "Name of the CloudTrail trail."
  type        = string
  default     = "security-baseline-trail"
}

variable "bucket_name_prefix" {
  description = "Prefix for the CloudTrail/Config log bucket name. A random suffix is appended to avoid global S3 name collisions."
  type        = string
  default     = "security-baseline-logs"
}

variable "enable_cloudwatch_alarms" {
  description = "Whether to deliver CloudTrail to a CloudWatch Logs group and create CIS-recommended metric-filter alarms (root account usage, IAM policy changes). Off by default to keep the credential-free plan path minimal."
  type        = bool
  default     = false
}

variable "cloudwatch_log_retention_days" {
  description = "Retention period for the CloudTrail CloudWatch Logs group, if enabled."
  type        = number
  default     = 90
}

variable "alarm_actions" {
  description = "ARNs (e.g. an SNS topic) to notify when a metric-filter alarm fires. Left empty by default — the alarms still exist and demonstrate detection, they just have no configured notification target."
  type        = list(string)
  default     = []
}

variable "enable_aws_config" {
  description = "Whether to enable an AWS Config recorder + delivery channel + a couple of managed rules. Off by default: this is a real running service with a small ongoing cost (~$1-3/mo) once actually applied, not something to enable in a zero-cost demo by default."
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Whether to enable VPC Flow Logs for a specific VPC. Off by default and requires var.vpc_id to be set — this module never looks up 'the default VPC' via a data source, to keep plan credential-free."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID to enable flow logs for. Required only if enable_vpc_flow_logs is true."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to taggable resources created by this module."
  type        = map(string)
  default     = {}
}
