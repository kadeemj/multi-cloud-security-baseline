# examples/insecure

Deliberately misconfigured fixtures — **never `terraform apply`'d, ever** —
that exist purely to give the "surfacing misconfigurations" resume claim a
concrete before/after. CI scans this directory with `--soft-fail` so a real
finding here never turns the build red; it just gets published to the job
summary and the Security tab.

## aws/ — 17 failed checks (9 passed)

| Misconfiguration | Representative Checkov findings |
|---|---|
| S3 bucket with a public-read ACL | `CKV_AWS_20`, `CKV2_AWS_6` (no public access block) |
| No bucket encryption / versioning | `CKV_AWS_19`, `CKV_AWS_21`, `CKV_AWS_145` |
| IAM policy with `"Action": "*"`, `"Resource": "*"` | `CKV_AWS_1`/`CKV_AWS_62` (full admin), `CKV_AWS_49`/`CKV_AWS_63` (wildcard action), `CKV_AWS_356` (wildcard resource) |

## gcp/ — 7 failed checks (3 passed)

| Misconfiguration | Representative Checkov findings |
|---|---|
| GCS bucket IAM-bound to `allUsers` | `CKV_GCP_28` |
| Bucket missing uniform bucket-level access | `CKV_GCP_29` |
| Bucket missing enforced public access prevention | `CKV_GCP_114` |
| Primitive `roles/owner` bound at project level | `CKV_GCP_117` |

Run it yourself: `../../scripts/scan.sh aws insecure` / `../../scripts/scan.sh gcp insecure`.
Exact counts can shift slightly as Checkov's rule set evolves — re-run
`checkov --list` against the pinned version in `scripts/scan.sh` if these
ever look stale.
