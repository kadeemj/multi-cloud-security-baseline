variable "project_id" {
  description = "GCP project ID this module manages KMS/storage resources in. Passed explicitly rather than looked up via data.google_project, so this module can plan with zero cloud credentials."
  type        = string
}

variable "region" {
  description = "Region for the KMS key ring and the CMEK-encrypted storage bucket. Both must be in the same location for CMEK to work."
  type        = string
  default     = "us-central1"
}

variable "key_ring_name_prefix" {
  description = "Prefix for the KMS key ring name. A random suffix is appended, since key rings can never be deleted and their names are permanently reserved."
  type        = string
  default     = "security-baseline-keyring"
}

variable "crypto_key_name" {
  description = "Name of the KMS crypto key."
  type        = string
  default     = "security-baseline-key"
}

variable "rotation_period" {
  description = "KMS key rotation period, as a duration string in seconds. CIS GCP Foundation Benchmark recommends <= 90 days (7776000s)."
  type        = string
  default     = "7776000s"
}

variable "bucket_name_prefix" {
  description = "Prefix for the CMEK-encrypted storage bucket name. A random suffix is appended to avoid global GCS name collisions."
  type        = string
  default     = "security-baseline-cmek-bucket"
}

variable "resolve_gcs_service_account_via_api" {
  description = "Whether to look up the project's GCS service agent (via data.google_storage_project_service_account) and grant it decrypt rights on the KMS key. This data source requires WORKING GCP credentials even during `terraform plan` — off by default so this module plans with zero cloud credentials. Flip to true only for a real, credentialed apply; otherwise the bucket's CMEK configuration will exist in the plan but the actual apply would fail without this grant."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Labels applied to taggable resources created by this module (GCP calls these 'labels', not 'tags')."
  type        = map(string)
  default     = {}
}
