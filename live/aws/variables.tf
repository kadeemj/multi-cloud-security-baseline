variable "aws_account_id" {
  description = "AWS account ID this baseline is deployed to. Passed explicitly (never looked up via data.aws_caller_identity) so this root module can plan with zero cloud credentials. Get the real value with: aws sts get-caller-identity --query Account --output text"
  type        = string
}

variable "skip_credential_validation" {
  description = "Skip the AWS provider's eager sts:GetCallerIdentity call during plan — required for a credential-free plan with dummy credentials (AWS_ACCESS_KEY_ID=test etc). Leave false for a real apply."
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region for the provider (CloudTrail itself is multi-region regardless)."
  type        = string
  default     = "us-east-1"
}

variable "enable_cloudwatch_alarms" {
  description = "Passed through to aws-logging-baseline — enable CloudWatch Logs delivery + CIS metric-filter alarms."
  type        = bool
  default     = false
}

variable "enable_aws_config" {
  description = "Passed through to aws-logging-baseline — enable AWS Config recorder + managed rules (~$1-3/mo if actually applied)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all taggable resources in this baseline."
  type        = map(string)
  default = {
    Project = "multi-cloud-security-baseline"
  }
}
