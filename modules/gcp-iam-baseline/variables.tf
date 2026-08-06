variable "project_id" {
  description = "GCP project ID this module manages IAM for. Passed explicitly rather than looked up via data.google_project, so this module can plan with zero cloud credentials."
  type        = string
}

variable "custom_role_id" {
  description = "ID (not display name) of the least-privilege custom role."
  type        = string
  default     = "securityBaselineAuditor"
}

variable "custom_role_title" {
  description = "Human-readable title for the custom role."
  type        = string
  default     = "Security Baseline Auditor"
}

variable "custom_role_permissions" {
  description = "Read-only permissions granted to the example least-privilege role, demonstrating the pattern to follow instead of binding primitive roles/owner or roles/editor."
  type        = list(string)
  default = [
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy",
    "iam.roles.get",
    "iam.roles.list",
    "iam.serviceAccounts.list",
    "logging.logEntries.list",
    "logging.sinks.get",
    "logging.sinks.list",
    "storage.buckets.getIamPolicy",
    "cloudkms.cryptoKeys.list",
  ]
}

variable "example_member" {
  description = "Principal to bind the least-privilege custom role to, e.g. \"serviceAccount:auditor@my-project.iam.gserviceaccount.com\" or \"user:name@example.com\". Required (no default) — supply a real principal for an actual apply, or a placeholder for a credential-free plan."
  type        = string
}

variable "enable_disable_sa_key_creation_org_policy" {
  description = "Whether to set the constraints/iam.disableServiceAccountKeyCreation org policy at project scope. Off by default and best-effort: this needs org-policy-admin-equivalent permission on the project and its exact behavior on a project with no parent Organization has not been verified end-to-end — see module README."
  type        = bool
  default     = false
}
