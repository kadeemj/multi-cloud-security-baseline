output "custom_role_id" {
  value = module.iam_baseline.custom_role_id
}

output "crypto_key_id" {
  value = module.encryption_baseline.crypto_key_id
}

output "cmek_bucket_name" {
  value = module.encryption_baseline.cmek_bucket_name
}

output "audit_log_bucket_name" {
  value = module.logging_baseline.audit_log_bucket_name
}
