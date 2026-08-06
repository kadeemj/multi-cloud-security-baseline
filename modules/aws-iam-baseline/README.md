# aws-iam-baseline

Account-wide IAM hardening: a strong password policy plus a worked example of
a least-privilege role, to demonstrate the pattern the rest of the account
should follow instead of wildcard admin policies.

## CIS mapping

| Control | CIS AWS Foundations v3.0 | Resource |
|---|---|---|
| Password length ≥ 14 | 1.9 | `aws_iam_account_password_policy` |
| Password reuse prevention ≥ 24 | 1.10 | `aws_iam_account_password_policy` |
| Password expiration ≤ 90 days | 1.11 | `aws_iam_account_password_policy` |
| No wildcard-action / wildcard-resource IAM policies | 1.16 (illustrative) | `aws_iam_policy.example_readonly_auditor` |

## Inputs

| Name | Description | Default |
|---|---|---|
| `password_policy_minimum_length` | Minimum password length | `14` |
| `password_policy_reuse_prevention` | Previous passwords remembered | `24` |
| `password_policy_max_age` | Days before password expires | `90` |
| `password_policy_require_symbols` / `_numbers` / `_uppercase` / `_lowercase` | Character-class requirements | `true` |
| `example_role_name` | Name for the example least-privilege role | `security-baseline-readonly-auditor` |
| `tags` | Tags applied to taggable resources | `{}` |

## Outputs

| Name | Description |
|---|---|
| `password_policy_id` | ID of the account password policy |
| `example_role_arn` | ARN of the example IAM role |
| `example_role_policy_arn` | ARN of the example IAM policy |

## Notes

This module does **not** attempt account-wide IAM enforcement (e.g. SCPs
denying non-compliant policies) — that requires AWS Organizations, which is
out of scope for an account/project-level baseline. See the repo root
README's "excluded by design" section.
