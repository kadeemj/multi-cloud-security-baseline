output "audit_log_bucket_name" {
  description = "Name of the bucket receiving exported audit logs."
  value       = google_storage_bucket.audit_logs.name
}

output "sink_name" {
  description = "Name of the log sink."
  value       = google_logging_project_sink.audit_export.name
}

output "sink_writer_identity" {
  description = "Service-agent identity the sink writes as (also granted objectCreator on the destination bucket)."
  value       = google_logging_project_sink.audit_export.writer_identity
}
