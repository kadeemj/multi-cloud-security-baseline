output "password_policy_id" {
  description = "ID of the account password policy resource."
  value       = aws_iam_account_password_policy.this.id
}

output "example_role_arn" {
  description = "ARN of the least-privilege example IAM role."
  value       = aws_iam_role.example_readonly_auditor.arn
}

output "example_role_policy_arn" {
  description = "ARN of the least-privilege example IAM policy."
  value       = aws_iam_policy.example_readonly_auditor.arn
}
