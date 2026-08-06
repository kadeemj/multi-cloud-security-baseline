# Dummy values used only for the credential-free `terraform plan` in CI and
# local validation. Do NOT use these for a real apply — copy this file to a
# gitignored terraform.tfvars with your real project ID instead.
project_id = "security-baseline-demo-000000"
region     = "us-central1"

example_member = "serviceAccount:placeholder@security-baseline-demo-000000.iam.gserviceaccount.com"

tags = {
  project     = "multi-cloud-security-baseline"
  environment = "ci"
}
