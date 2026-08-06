variable "project_id" {
  description = "GCP project ID this baseline is deployed to. Passed explicitly (never looked up via data.google_project) so this root module can plan with zero cloud credentials."
  type        = string
}

variable "region" {
  description = "Region for the provider default and for regional resources (KMS key ring, buckets)."
  type        = string
  default     = "us-central1"
}

variable "example_member" {
  description = "Principal to bind the least-privilege custom IAM role to. Passed through to gcp-iam-baseline."
  type        = string
}

variable "resolve_gcs_service_account_via_api" {
  description = "Passed through to gcp-encryption-baseline. Requires WORKING GCP credentials even during plan — leave false for the credential-free path, flip to true only for a real, credentialed apply."
  type        = bool
  default     = false
}

variable "enable_disable_sa_key_creation_org_policy" {
  description = "Passed through to gcp-iam-baseline — best-effort Org Policy restricting service-account key creation."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Labels applied to all taggable resources in this baseline."
  type        = map(string)
  default = {
    project = "multi-cloud-security-baseline"
  }
}
