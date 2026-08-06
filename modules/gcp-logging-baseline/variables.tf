variable "project_id" {
  description = "GCP project ID this module manages audit logging for. Passed explicitly rather than looked up via data.google_project, so this module can plan with zero cloud credentials."
  type        = string
}

variable "region" {
  description = "Location for the audit-log destination bucket."
  type        = string
  default     = "us-central1"
}

variable "audit_log_bucket_name_prefix" {
  description = "Prefix for the audit-log destination bucket name. A random suffix is appended to avoid global GCS name collisions."
  type        = string
  default     = "security-baseline-audit-logs"
}

variable "sink_name" {
  description = "Name of the log sink exporting project audit logs to the destination bucket."
  type        = string
  default     = "security-baseline-audit-sink"
}

variable "log_filter" {
  description = "Sink filter. Empty string exports all log entries in the project."
  type        = string
  default     = ""
}

variable "retention_period_seconds" {
  description = "Retention period (seconds) enforced on the audit-log bucket via GCS Bucket Lock. WARNING: Bucket Lock is irreversible — once locked, this period can only be increased, never decreased or removed, and the bucket cannot be deleted until every object individually ages past it."
  type        = number
  default     = 7776000 # 90 days
}

variable "tags" {
  description = "Labels applied to taggable resources created by this module (GCP calls these 'labels', not 'tags')."
  type        = map(string)
  default     = {}
}
