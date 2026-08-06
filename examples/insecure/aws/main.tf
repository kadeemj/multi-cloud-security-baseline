# INTENTIONALLY INSECURE — a Checkov scan fixture only, never
# terraform-applied. Exists purely to give the "before" half of a
# before/after demo for the hardened baseline in modules/ and live/aws.
# Do not copy anything from this file into real infrastructure.
# See examples/insecure/README.md.

resource "aws_s3_bucket" "insecure_public_bucket" {
  bucket = "insecure-example-public-bucket"
}

resource "aws_s3_bucket_acl" "insecure_public_bucket" {
  bucket = aws_s3_bucket.insecure_public_bucket.id
  acl    = "public-read"
}

data "aws_iam_policy_document" "insecure_admin_policy" {
  statement {
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "insecure_admin_policy" {
  name   = "insecure-example-full-admin-policy"
  policy = data.aws_iam_policy_document.insecure_admin_policy.json
}
