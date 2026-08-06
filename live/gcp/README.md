# live/gcp

The deployable root module composing all three `gcp-*` baseline modules.
Unlike `examples/insecure/`, this is meant to actually be applied.

## Plan with zero credentials

```sh
./scripts/gen-fake-gcp-creds.sh /tmp/fake-gcp-credentials.json
export GOOGLE_APPLICATION_CREDENTIALS=/tmp/fake-gcp-credentials.json

terraform init -backend=false
terraform plan -var-file=ci.tfvars
```

`gen-fake-gcp-creds.sh` generates a real, syntactically-valid, throwaway
self-signed key at runtime — it's never committed, since even a fake
committed PEM block tends to trip GitHub secret-scanning on a public repo.

Keep `resolve_gcs_service_account_via_api = false` (the default) for this
credential-free path — flipping it on makes `gcp-encryption-baseline` issue
a live API call during plan, which the fake credentials can't satisfy.

## Apply for real

1. `gcloud auth application-default login` (or a real service-account key) so `GOOGLE_APPLICATION_CREDENTIALS` points at working credentials.
2. Copy `ci.tfvars` to a **gitignored** `terraform.tfvars` and fill in your real `project_id` and `example_member`.
3. Set `resolve_gcs_service_account_via_api = true` in that file so the CMEK grant is actually created.
4. Optionally copy `backend.tf.example` to `backend.tf` for remote state.
5. `terraform init && terraform plan -var-file=terraform.tfvars && terraform apply -var-file=terraform.tfvars`

See the module READMEs (`modules/gcp-*-baseline/`) — in particular
`gcp-logging-baseline`'s Bucket Lock warning and `gcp-encryption-baseline`'s
KMS teardown notes — before applying for real.
