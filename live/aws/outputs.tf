output "password_policy_id" {
  value = module.iam_baseline.password_policy_id
}

output "example_role_arn" {
  value = module.iam_baseline.example_role_arn
}

output "kms_key_arn" {
  value = module.encryption_baseline.kms_key_arn
}

output "trail_arn" {
  value = module.logging_baseline.trail_arn
}

output "log_bucket_id" {
  value = module.logging_baseline.log_bucket_id
}
