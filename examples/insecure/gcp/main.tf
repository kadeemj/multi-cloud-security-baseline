# INTENTIONALLY INSECURE — a Checkov scan fixture only, never
# terraform-applied. Exists purely to give the "before" half of a
# before/after demo for the hardened baseline in modules/ and live/gcp.
# Do not copy anything from this file into real infrastructure.
# See examples/insecure/README.md.

resource "google_storage_bucket" "insecure_public_bucket" {
  name     = "insecure-example-public-bucket"
  project  = "insecure-example-project"
  location = "US"
}

resource "google_storage_bucket_iam_member" "insecure_public_access" {
  bucket = google_storage_bucket.insecure_public_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_project_iam_member" "insecure_primitive_owner" {
  project = "insecure-example-project"
  role    = "roles/owner"
  member  = "user:example-insecure-user@example.com"
}
