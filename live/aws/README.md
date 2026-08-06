# live/aws

The deployable root module composing all three `aws-*` baseline modules.
Unlike `examples/insecure/`, this is meant to actually be applied.

## Plan with zero credentials

```sh
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

terraform init -backend=false
terraform plan -var-file=ci.tfvars
```

This shows every resource this baseline would create, with no real AWS
account involved — the provider never makes a live API call because every
resource here is a fresh `resource` block, not a `data` lookup of
pre-existing infrastructure. See the repo root README for why.

## Apply for real

1. `aws sts get-caller-identity --query Account --output text` to get your real account ID.
2. Copy `ci.tfvars` to a **gitignored** `terraform.tfvars` and fill in your real `aws_account_id`.
3. Optionally copy `backend.tf.example` to `backend.tf` for remote state.
4. `terraform init && terraform plan -var-file=terraform.tfvars && terraform apply -var-file=terraform.tfvars`

See the module READMEs (`modules/aws-*-baseline/`) and the repo root README's
cost notes before enabling `enable_aws_config` or `enable_cloudwatch_alarms`.
