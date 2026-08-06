# gcp-encryption-baseline

A KMS key ring/key with a 90-day rotation period, plus a CMEK-encrypted
example storage bucket (uniform bucket-level access, enforced public access
prevention, versioning) and its own dedicated access-log bucket.

## CIS mapping

| Control | CIS GCP Foundation Benchmark v2.0 | Resource |
|---|---|---|
| KMS key rotation <= 90 days | 1.10 | `google_kms_crypto_key.this` |
| Uniform bucket-level access | 5.1 | `google_storage_bucket.cmek` |
| Public access prevention enforced | 5.2 (illustrative) | `google_storage_bucket.cmek` |
| Bucket versioning | (illustrative) | `google_storage_bucket.cmek` |

## The CMEK / GCS-service-agent landmine

Granting the project's GCS service agent decrypt rights on the KMS key
normally requires `data.google_storage_project_service_account` — which
requires **working GCP credentials even during `terraform plan`** (it's a
live API call, not a static lookup). That's gated behind
`var.resolve_gcs_service_account_via_api` (default `false`) so this module
plans with zero credentials. **Flip it to `true` only for a real,
credentialed apply** — otherwise the plan will show the bucket's CMEK
configuration, but an actual apply would fail without the grant.

## Why there's a second bucket

`google_storage_bucket.access_logs` exists purely so `google_storage_bucket.cmek`
can have access logging enabled without logging to itself (Checkov flags
both "no access logging" and "logs to itself"). It has no logging of its own
— chaining log buckets indefinitely would be infinite regress; see the
inline `#checkov:skip` in `main.tf`.

## Inputs

| Name | Description | Default |
|---|---|---|
| `project_id` | GCP project ID (required, no default) | — |
| `region` | Location for the key ring and buckets | `us-central1` |
| `key_ring_name_prefix` | Key ring name prefix (random suffix appended) | `security-baseline-keyring` |
| `crypto_key_name` | Crypto key name | `security-baseline-key` |
| `rotation_period` | KMS rotation period (seconds, as a duration string) | `7776000s` (90 days) |
| `bucket_name_prefix` | CMEK bucket name prefix (random suffix appended) | `security-baseline-cmek-bucket` |
| `resolve_gcs_service_account_via_api` | Look up + grant the GCS service agent decrypt rights (needs live credentials) | `false` |
| `tags` | Labels applied to taggable resources | `{}` |

## Outputs

| Name | Description |
|---|---|
| `key_ring_id` / `crypto_key_id` | KMS resources |
| `cmek_bucket_name` | The CMEK-encrypted example bucket |
| `access_logs_bucket_name` | Its dedicated access-log bucket |

## Cost & teardown notes

KMS key *material* is billed at a low per-version rate indefinitely — a
`terraform destroy` does **not** delete key rings (impossible in GCP) and
`prevent_destroy` blocks deleting the crypto key too. This is a real
asymmetry versus AWS KMS, which supports a clean 7-30 day scheduled
deletion. Budget for a small ongoing charge if you ever apply this for real.
