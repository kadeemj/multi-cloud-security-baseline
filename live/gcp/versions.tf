terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }

  # No backend block here on purpose — the default is local state, which
  # keeps `terraform init -backend=false` credential-free and simple. See
  # backend.tf.example for wiring up a real remote backend.
}

provider "google" {
  project = var.project_id
  region  = var.region
}
