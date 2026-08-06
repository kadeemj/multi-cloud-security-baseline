# CIS GCP Foundation Benchmark v2.0 §2.1 — Cloud Audit Logging configured
# for admin activity + data access (read + write) across all services.
resource "google_project_iam_audit_config" "all_services" {
  project = var.project_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "audit_logs" {
  # This bucket is itself the CIS-required audit-log destination — layering
  # GCS-level access logging on top of the log bucket is out of scope for
  # the curated baseline (the same tradeoff aws-logging-baseline makes for
  # its CloudTrail bucket; see that module's #checkov:skip=CKV_AWS_18).
  #checkov:skip=CKV_GCP_62:this bucket is itself the audit-log destination; a further access-log bucket for the log bucket is out of scope for the curated baseline
  name                        = "${var.audit_log_bucket_name_prefix}-${random_id.bucket_suffix.hex}"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = var.tags

  versioning {
    enabled = true
  }

  # Bucket Lock: makes the retention period immutable and tamper-evident —
  # not even a project owner can delete these logs early. Irreversible; see
  # var.retention_period_seconds and the module README before applying for real.
  retention_policy {
    is_locked        = true
    retention_period = var.retention_period_seconds
  }
}

# CIS GCP Foundation Benchmark v2.0 §2.2-2.3 (illustrative) — export audit
# logs to a bucket with its own retention, independent of Cloud Logging's
# default retention window.
resource "google_logging_project_sink" "audit_export" {
  name                   = var.sink_name
  project                = var.project_id
  destination            = "storage.googleapis.com/${google_storage_bucket.audit_logs.name}"
  filter                 = var.log_filter
  unique_writer_identity = true
}

# Grants the sink's own service-agent identity (a same-plan resource
# attribute, not a live lookup) write access to just this bucket — not a
# project-wide role.
resource "google_storage_bucket_iam_member" "sink_writer" {
  bucket = google_storage_bucket.audit_logs.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.audit_export.writer_identity
}
