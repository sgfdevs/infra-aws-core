output "backend_bucket_name" {
  description = "S3 bucket name for OpenTofu state storage."
  value       = aws_s3_bucket.tfstate_state.bucket
}

output "backend_table_name" {
  description = "DynamoDB table name for state locking."
  value       = aws_dynamodb_table.tflock_state.name
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC authentication."
  value       = aws_iam_role.github_actions_terraform.arn
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
