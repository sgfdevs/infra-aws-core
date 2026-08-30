output "backend_bucket_name" {
  description = "S3 bucket name for OpenTofu state storage."
  value       = aws_s3_bucket.tfstate_state.bucket
}

output "backend_table_name" {
  description = "DynamoDB table name for state locking."
  value       = aws_dynamodb_table.tflock_state.name
}

output "github_actions_app_config_role_arn" {
  description = "IAM role ARN for infra-app-config GitHub Actions."
  value       = module.github_actions.app_config_role_arn
  sensitive   = true
}

output "github_actions_dns_role_arn" {
  description = "IAM role ARN for infra-dns GitHub Actions."
  value       = module.github_actions.dns_role_arn
  sensitive   = true
}

output "github_actions_gh_role_arn" {
  description = "IAM role ARN for infra-gh GitHub Actions."
  value       = module.github_actions.gh_role_arn
  sensitive   = true
}

output "github_actions_vm_workloads_role_arn" {
  description = "IAM role ARN for infra-vm-workloads GitHub Actions."
  value       = module.github_actions.vm_workloads_role_arn
  sensitive   = true
}

output "ses_email_identity_arns" {
  description = "ARNs of the SES identities used for outbound email."
  value       = { for domain, identity in aws_sesv2_email_identity.domain : domain => identity.arn }
}

output "ses_mail_from_domains" {
  description = "Custom MAIL FROM domains used by SES."
  value       = { for domain, attributes in aws_sesv2_email_identity_mail_from_attributes.domain : domain => attributes.mail_from_domain }
}
