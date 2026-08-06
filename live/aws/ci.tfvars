# Dummy values used only for the credential-free `terraform plan` in CI and
# local validation. Do NOT use these for a real apply — copy this file to a
# gitignored terraform.tfvars with your real account ID instead.
aws_account_id             = "123456789012"
aws_region                 = "us-east-1"
skip_credential_validation = true

tags = {
  Project     = "multi-cloud-security-baseline"
  Environment = "ci"
}
