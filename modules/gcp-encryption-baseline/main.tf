resource "random_id" "key_ring_suffix" {
  byte_length = 4
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Key rings can never be deleted (only the crypto keys within them can be
# scheduled for destruction), which is why the name carries a random suffix
# — a `terraform destroy` + re-apply cycle must never collide with a
# permanently-reserved name.
resource "google_kms_key_ring" "this" {
  name     = "${var.key_ring_name_prefix}-${random_id.key_ring_suffix.hex}"
  location = var.region
  project  = var.project_id
}

# CIS GCP Foundation Benchmark (illustrative) — rotation <= 90 days.
# `prevent_destroy` guards against accidental deletion; GCP KMS key
# *material* is billed at a low per-version rate indefinitely even if
# orphaned by a destroy that skips this key, which is a real cost asymmetry
# versus AWS KMS (see module README).
resource "google_kms_crypto_key" "this" {
  name            = var.crypto_key_name
  key_ring        = google_kms_key_ring.this.id
  rotation_period = var.rotation_period

  lifecycle {
    prevent_destroy = true
  }
}

# Landmine avoided here: resolving the GCS-per-project service agent's email
# normally requires data.google_storage_project_service_account, which needs
# WORKING GCP credentials even during `plan` (it's a live API call, not a
# static lookup). Gated off by default so this module plans with zero
# credentials; flip on only for a real, credentialed apply.
data "google_storage_project_service_account" "gcs" {
  count   = var.resolve_gcs_service_account_via_api ? 1 : 0
  project = var.project_id
}

resource "google_kms_crypto_key_iam_member" "gcs_decrypt" {
  count         = var.resolve_gcs_service_account_via_api ? 1 : 0
  crypto_key_id = google_kms_crypto_key.this.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs[0].email_address}"
}

# CIS GCP Foundation Benchmark (illustrative) — uniform bucket-level access,
# enforced public access prevention, versioning, CMEK.
resource "google_storage_bucket" "cmek" {
  name                        = "${var.bucket_name_prefix}-${random_id.bucket_suffix.hex}"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = var.tags

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.this.id
  }

  logging {
    log_bucket = google_storage_bucket.access_logs.name
  }

  depends_on = [google_kms_crypto_key_iam_member.gcs_decrypt]
}

# A small, separate bucket receiving this bucket's own access logs
# (CKV_GCP_62/63 require access logging, and require it NOT log to itself).
resource "google_storage_bucket" "access_logs" {
  #checkov:skip=CKV_GCP_62:this is the designated log-receiver bucket; chaining another log bucket to log this one would be infinite regress
  name                        = "${var.bucket_name_prefix}-access-logs-${random_id.bucket_suffix.hex}"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = var.tags

  versioning {
    enabled = true
  }
}
