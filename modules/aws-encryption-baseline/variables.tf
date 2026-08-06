variable "aws_account_id" {
  description = "AWS account ID the key policy's root-principal statement applies to. Passed explicitly (never looked up via data.aws_caller_identity) so this module can plan with zero cloud credentials. Get the real value with: aws sts get-caller-identity --query Account --output text"
  type        = string
}

variable "key_alias" {
  description = "Alias for the customer-managed KMS key (without the alias/ prefix)."
  type        = string
  default     = "security-baseline-cmk"
}

variable "key_deletion_window_in_days" {
  description = "Waiting period before the KMS key is deleted after a destroy. AWS allows 7-30 days."
  type        = number
  default     = 30
}

variable "enable_ebs_encryption_by_default" {
  description = "Whether to set account-level EBS-encryption-by-default (region-scoped singleton setting)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to taggable resources created by this module."
  type        = map(string)
  default     = {}
}
