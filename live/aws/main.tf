module "iam_baseline" {
  source = "../../modules/aws-iam-baseline"

  tags = var.tags
}

module "encryption_baseline" {
  source = "../../modules/aws-encryption-baseline"

  aws_account_id = var.aws_account_id
  tags           = var.tags
}

module "logging_baseline" {
  source = "../../modules/aws-logging-baseline"

  aws_account_id           = var.aws_account_id
  kms_key_arn              = module.encryption_baseline.kms_key_arn
  enable_cloudwatch_alarms = var.enable_cloudwatch_alarms
  enable_aws_config        = var.enable_aws_config
  tags                     = var.tags
}
