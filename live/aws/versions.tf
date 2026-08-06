terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # No backend block here on purpose — the default is local state, which
  # keeps `terraform init -backend=false` credential-free and simple. See
  # backend.tf.example for wiring up a real remote backend.
}

provider "aws" {
  region = var.aws_region

  # The AWS provider (confirmed empirically on v6.58.0) eagerly calls
  # sts:GetCallerIdentity during provider configuration, before planning any
  # resource — dummy AWS_ACCESS_KEY_ID/SECRET alone are NOT enough for a
  # credential-free `terraform plan`. These two flags (the same pair
  # LocalStack's own Terraform docs recommend for mocked/no-real-account
  # testing) skip that eager validation call. Leave var.skip_credential_validation
  # at its default `false` for a real, credentialed apply.
  skip_credentials_validation = var.skip_credential_validation
  skip_requesting_account_id  = var.skip_credential_validation
}
