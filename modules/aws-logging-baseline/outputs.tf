output "trail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = aws_cloudtrail.this.arn
}

output "log_bucket_arn" {
  description = "ARN of the S3 bucket receiving CloudTrail (and, if enabled, Config) logs."
  value       = aws_s3_bucket.logs.arn
}

output "log_bucket_id" {
  description = "Name/ID of the S3 log bucket."
  value       = aws_s3_bucket.logs.id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudTrail CloudWatch Logs group, if enable_cloudwatch_alarms is true."
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_log_group.cloudtrail[0].name : null
}

output "config_recorder_name" {
  description = "Name of the AWS Config recorder, if enable_aws_config is true."
  value       = var.enable_aws_config ? aws_config_configuration_recorder.this[0].name : null
}
