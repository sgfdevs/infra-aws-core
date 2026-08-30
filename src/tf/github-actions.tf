module "github_actions" {
  source = "./modules/github-actions"

  application_ses_policy_arns       = local.application_ses_policy_arns
  application_ses_senders           = local.application_ses_senders
  aws_account_id                    = data.aws_caller_identity.current.account_id
  oidc_provider_arn                 = aws_iam_openid_connect_provider.github_actions.arn
  ses_identity_arns                 = [for identity in aws_sesv2_email_identity.domain : identity.arn]
  sgfdevs_k3s_oidc_provider_arn     = aws_iam_openid_connect_provider.sgfdevs_k3s.arn
  sgfdevs_k3s_workload_boundary_arn = aws_iam_policy.sgfdevs_k3s_kubernetes_workload_boundary.arn
  state_bucket_arn                  = aws_s3_bucket.tfstate_state.arn
  state_bucket_name                 = aws_s3_bucket.tfstate_state.bucket
  state_lock_table_arn              = aws_dynamodb_table.tflock_state.arn
  vm_workloads_parameter_arn        = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/vm-workloads/sgfdevs/infra-vm-workloads/*"
}
