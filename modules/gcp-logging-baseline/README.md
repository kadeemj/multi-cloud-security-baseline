# gcp-logging-baseline

Project-wide Cloud Audit Logging (admin activity + data access, read and
write, across all services) exported to a dedicated, locked-down GCS bucket
with its own retention — independent of Cloud Logging's default window.

## CIS mapping

| Control | CIS GCP Foundation Benchmark v2.0 | Resource |
|---|---|---|
| Cloud Audit Logging enabled for all services/users | 2.1 | `google_project_iam_audit_config.all_services` |
| Log export / retention independent of default | 2.2-2.3 (illustrative) | `google_logging_project_sink.audit_export` |
| Destination bucket not publicly accessible | 5.1-5.2 (illustrative) | `google_storage_bucket.audit_logs` |

## Bucket Lock is irreversible

The destination bucket enforces `retention_policy { is_locked = true }` (GCS
Bucket Lock) so the audit trail is tamper-evident — not even a project owner
can delete logs before `var.retention_period_seconds` elapses. **Once
locked, the retention period can only be increased, never decreased or
removed, and the bucket cannot be deleted until every object individually
ages past it.** Choose `retention_period_seconds` deliberately before a real
apply; the default is 90 days.

## Least-privilege sink identity

The sink's own service-agent identity
(`google_logging_project_sink.audit_export.writer_identity` — a same-plan
resource attribute, not a live lookup) is granted `roles/storage.objectCreator`
on just the destination bucket, not a project-wide storage role.

## Inputs

| Name | Description | Default |
|---|---|---|
| `project_id` | GCP project ID (required, no default) | — |
| `region` | Location for the destination bucket | `us-central1` |
| `audit_log_bucket_name_prefix` | Bucket name prefix (random suffix appended) | `security-baseline-audit-logs` |
| `sink_name` | Log sink name | `security-baseline-audit-sink` |
| `log_filter` | Sink filter (`""` exports all project log entries) | `""` |
| `retention_period_seconds` | Bucket Lock retention period — irreversible once applied for real | `7776000` (90 days) |
| `tags` | Labels applied to taggable resources | `{}` |

## Outputs

| Name | Description |
|---|---|
| `audit_log_bucket_name` | Destination bucket |
| `sink_name` | Log sink name |
| `sink_writer_identity` | The sink's service-agent identity |
