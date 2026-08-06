output "custom_role_id" {
  description = "Fully-qualified ID of the least-privilege custom role."
  value       = google_project_iam_custom_role.readonly_auditor.id
}

output "custom_role_name" {
  description = "Name (role_id) of the custom role."
  value       = google_project_iam_custom_role.readonly_auditor.role_id
}
