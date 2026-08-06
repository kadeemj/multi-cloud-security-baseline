output "key_ring_id" {
  description = "ID of the KMS key ring."
  value       = google_kms_key_ring.this.id
}

output "crypto_key_id" {
  description = "ID of the KMS crypto key, for use as a CMEK key elsewhere in the baseline."
  value       = google_kms_crypto_key.this.id
}

output "cmek_bucket_name" {
  description = "Name of the CMEK-encrypted example bucket."
  value       = google_storage_bucket.cmek.name
}

output "access_logs_bucket_name" {
  description = "Name of the bucket receiving the CMEK bucket's own access logs."
  value       = google_storage_bucket.access_logs.name
}
