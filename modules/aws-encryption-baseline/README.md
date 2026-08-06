# aws-encryption-baseline

A shared customer-managed KMS key (rotation enabled) plus account-level EBS
default encryption. Other modules (`aws-logging-baseline`) consume
`kms_key_arn` as an input rather than looking the key up — keeping module
dependencies explicit and avoiding any data-source lookups.

## CIS mapping

| Control | CIS AWS Foundations v3.0 | Resource |
|---|---|---|
| Customer-managed key with rotation enabled | 3.x (illustrative) | `aws_kms_key.cmk` |
| EBS encryption by default | 2.x (illustrative) | `aws_ebs_encryption_by_default` |

## Inputs

| Name | Description | Default |
|---|---|---|
| `aws_account_id` | Account ID for the key policy's root-principal statement (required, no default — get it with `aws sts get-caller-identity`) | — |
| `key_alias` | KMS alias name | `security-baseline-cmk` |
| `key_deletion_window_in_days` | Key deletion waiting period | `30` |
| `enable_ebs_encryption_by_default` | Toggle the account-level EBS default-encryption setting | `true` |
| `tags` | Tags applied to taggable resources | `{}` |

## Outputs

| Name | Description |
|---|---|
| `kms_key_arn` | Feed into other modules needing SSE-KMS / CloudTrail encryption |
| `kms_key_id` | Raw key ID |
| `kms_alias_arn` | Alias ARN |

## Cost note

A customer-managed KMS key costs ~$1/month plus per-request charges if
actually applied to a real AWS account. `terraform destroy` schedules a
clean 7-30 day deletion (`key_deletion_window_in_days`) — no orphaned
billing, unlike GCP KMS (see `gcp-encryption-baseline`).
