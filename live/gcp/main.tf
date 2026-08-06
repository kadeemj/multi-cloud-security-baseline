module "iam_baseline" {
  source = "../../modules/gcp-iam-baseline"

  project_id                                = var.project_id
  example_member                            = var.example_member
  enable_disable_sa_key_creation_org_policy = var.enable_disable_sa_key_creation_org_policy
}

module "encryption_baseline" {
  source = "../../modules/gcp-encryption-baseline"

  project_id                          = var.project_id
  region                              = var.region
  resolve_gcs_service_account_via_api = var.resolve_gcs_service_account_via_api
  tags                                = var.tags
}

module "logging_baseline" {
  source = "../../modules/gcp-logging-baseline"

  project_id = var.project_id
  region     = var.region
  tags       = var.tags
}
