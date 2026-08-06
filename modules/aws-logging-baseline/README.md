# aws-logging-baseline

A multi-region CloudTrail trail delivering KMS-encrypted, integrity-validated
logs to a dedicated, fully-locked-down S3 bucket. Optionally (all off by
default) extends into CloudWatch Logs with CIS-recommended alarms, AWS
Config, and VPC Flow Logs.

## CIS mapping

| Control | CIS AWS Foundations v3.0 | Resource | Enabled by default? |
|---|---|---|---|
| CloudTrail enabled in all regions | 3.1 | `aws_cloudtrail.this` | Yes |
| CloudTrail log file validation | 3.2 | `aws_cloudtrail.this` | Yes |
| S3 bucket not publicly accessible | 3.3 | `aws_s3_bucket_public_access_block.logs` | Yes |
| CloudTrail encrypted with CMK | 3.7 | `aws_cloudtrail.this` (`kms_key_id`) | Yes |
| CloudTrail integrated with CloudWatch Logs | 3.4 | `aws_cloudwatch_log_group.cloudtrail` | No — `enable_cloudwatch_alarms` |
| Root account usage alarm | 4.3 | `aws_cloudwatch_metric_alarm.root_account_usage` | No — `enable_cloudwatch_alarms` |
| IAM policy change alarm | 4.4 | `aws_cloudwatch_metric_alarm.iam_policy_changes` | No — `enable_cloudwatch_alarms` |
| AWS Config enabled | 3.5 (illustrative) | `aws_config_configuration_recorder.this` | No — `enable_aws_config` |
| VPC Flow Logs enabled | 3.9 | `aws_flow_log.this` | No — `enable_vpc_flow_logs` |

## Why the bucket policy uses a wildcarded trail-ARN pattern

The bucket policy's `aws:SourceArn` condition matches
`arn:aws:cloudtrail:*:<account>:trail/*` rather than this trail's own
computed ARN. Referencing the real trail ARN here would create a circular
dependency: the trail can't be created until the bucket policy grants it
write access, so the policy can't wait on an ARN that doesn't exist yet.
This is the same pattern AWS's own CloudTrail + KMS documentation uses.

## Inputs

| Name | Description | Default |
|---|---|---|
| `aws_account_id` | Account ID for the bucket policy's `SourceArn` condition (required, no default) | — |
| `kms_key_arn` | KMS key ARN from `aws-encryption-baseline` | — |
| `trail_name` | CloudTrail trail name | `security-baseline-trail` |
| `bucket_name_prefix` | Log bucket name prefix (random suffix appended) | `security-baseline-logs` |
| `enable_cloudwatch_alarms` | Enable CloudWatch Logs delivery + CIS metric-filter alarms | `false` |
| `cloudwatch_log_retention_days` | CloudTrail CloudWatch Logs retention | `90` |
| `alarm_actions` | ARNs (e.g. SNS topic) notified when an alarm fires | `[]` |
| `enable_aws_config` | Enable AWS Config recorder + delivery channel + managed rules | `false` |
| `enable_vpc_flow_logs` | Enable VPC Flow Logs (requires `vpc_id`) | `false` |
| `vpc_id` | VPC to enable flow logs for | `null` |
| `tags` | Tags applied to taggable resources | `{}` |

## Outputs

| Name | Description |
|---|---|
| `trail_arn` | ARN of the CloudTrail trail |
| `log_bucket_arn` / `log_bucket_id` | The dedicated log bucket |
| `cloudwatch_log_group_name` | Set only if `enable_cloudwatch_alarms` |
| `config_recorder_name` | Set only if `enable_aws_config` |

## Cost notes

The core trail + bucket cost only standard S3 storage (a few cents/month at
portfolio scale). AWS Config costs roughly $1-3/month per region once
actually applied — the reason it's opt-in rather than default-on.
