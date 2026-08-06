# Demonstrates the least-privilege pattern this baseline expects: a scoped
# custom role instead of binding a primitive roles/owner, roles/editor, or
# roles/viewer at project level (CIS GCP Foundation Benchmark §1.5-ish).
resource "google_project_iam_custom_role" "readonly_auditor" {
  role_id     = var.custom_role_id
  title       = var.custom_role_title
  description = "Least-privilege, read-only security-audit role — the pattern to follow instead of binding primitive roles/owner or roles/editor."
  project     = var.project_id
  permissions = var.custom_role_permissions
  stage       = "GA"
}

resource "google_project_iam_member" "readonly_auditor" {
  project = var.project_id
  role    = google_project_iam_custom_role.readonly_auditor.id
  member  = var.example_member
}

# Best-effort/opt-in: restrict service-account key creation at project
# scope. Requires org-policy-admin-equivalent permission on the project;
# behavior on a project with no parent Organization node should be verified
# during a real, credentialed apply rather than assumed from design alone.
resource "google_org_policy_policy" "disable_sa_key_creation" {
  count  = var.enable_disable_sa_key_creation_org_policy ? 1 : 0
  name   = "projects/${var.project_id}/policies/iam.disableServiceAccountKeyCreation"
  parent = "projects/${var.project_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}
