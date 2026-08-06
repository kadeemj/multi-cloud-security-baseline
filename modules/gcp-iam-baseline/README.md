# gcp-iam-baseline

A custom least-privilege IAM role bound to an example principal, demonstrating
the pattern to follow instead of binding primitive `roles/owner` /
`roles/editor` / `roles/viewer` at project level. Optionally (off by
default) restricts service-account key creation via an Org Policy.

## CIS mapping

| Control | CIS GCP Foundation Benchmark v2.0 | Resource | Enabled by default? |
|---|---|---|---|
| Avoid primitive roles at project level | 1.5-1.8 (illustrative) | `google_project_iam_custom_role` / `google_project_iam_member` | Yes |
| Restrict service-account key creation | 1.x (illustrative) | `google_org_policy_policy.disable_sa_key_creation` | No — `enable_disable_sa_key_creation_org_policy` |

## Inputs

| Name | Description | Default |
|---|---|---|
| `project_id` | GCP project ID (required, no default — never looked up via `data.google_project`) | — |
| `custom_role_id` | Custom role ID | `securityBaselineAuditor` |
| `custom_role_title` | Custom role display title | `Security Baseline Auditor` |
| `custom_role_permissions` | Read-only permissions granted to the example role | see `variables.tf` |
| `example_member` | Principal to bind the role to (required, no default) | — |
| `enable_disable_sa_key_creation_org_policy` | Enable the SA-key-creation-restriction Org Policy | `false` |

## Outputs

| Name | Description |
|---|---|
| `custom_role_id` | Fully-qualified custom role ID |
| `custom_role_name` | Role ID (short name) |

## Notes

`enable_disable_sa_key_creation_org_policy` needs project-owner-equivalent
permission and has only been designed for, not empirically verified against,
a project with no parent GCP Organization — verify during a real,
credentialed apply. This module does not attempt organization- or
folder-level IAM enforcement, which is out of scope for an account/project-
level baseline (see the repo root README's "excluded by design" section).
