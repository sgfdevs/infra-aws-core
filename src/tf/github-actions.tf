module "github_actions" {
  source = "./modules/github-actions"

  application_ses_policy_arns = local.application_ses_policy_arns
  application_ses_senders     = local.application_ses_senders
  aws_account_id              = data.aws_caller_identity.current.account_id
  oidc_provider_arn           = aws_iam_openid_connect_provider.github_actions.arn
  ses_identity_arns           = [for identity in aws_sesv2_email_identity.domain : identity.arn]
  state_bucket_arn            = aws_s3_bucket.tfstate_state.arn
  state_bucket_name           = aws_s3_bucket.tfstate_state.bucket
  state_lock_table_arn        = aws_dynamodb_table.tflock_state.arn
  vm_workloads_bootstrap_parameter_arns = [
    "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${local.sgfdevs_vms_eso_access_key_id_path}",
    "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${local.sgfdevs_vms_eso_secret_access_key_path}",
  ]
  vm_workloads_parameter_arn = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${local.sgfdevs_vms_parameter_path}"
}
