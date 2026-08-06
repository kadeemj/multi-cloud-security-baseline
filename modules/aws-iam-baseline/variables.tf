variable "password_policy_minimum_length" {
  description = "Minimum number of characters required in an IAM user password. CIS AWS Foundations v3.0 1.9 requires >= 14."
  type        = number
  default     = 14
}

variable "password_policy_reuse_prevention" {
  description = "Number of previous passwords IAM remembers to prevent reuse. CIS AWS Foundations v3.0 1.10 requires >= 24."
  type        = number
  default     = 24
}

variable "password_policy_max_age" {
  description = "Number of days before an IAM user password expires. CIS AWS Foundations v3.0 1.11 requires <= 90."
  type        = number
  default     = 90
}

variable "password_policy_require_symbols" {
  type    = bool
  default = true
}

variable "password_policy_require_numbers" {
  type    = bool
  default = true
}

variable "password_policy_require_uppercase" {
  type    = bool
  default = true
}

variable "password_policy_require_lowercase" {
  type    = bool
  default = true
}

variable "example_role_name" {
  description = "Name of the least-privilege example IAM role this module creates to demonstrate the pattern (scoped actions, no wildcard admin policy) that account IAM should follow."
  type        = string
  default     = "security-baseline-readonly-auditor"
}

variable "tags" {
  description = "Tags applied to all taggable resources created by this module."
  type        = map(string)
  default     = {}
}
