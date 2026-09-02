output "app_config_role_arn" {
  description = "IAM role ARN for infra-app-config GitHub Actions."
  value       = aws_iam_role.github_actions["app_config"].arn
}

output "dns_role_arn" {
  description = "IAM role ARN for infra-dns GitHub Actions."
  value       = aws_iam_role.github_actions["dns"].arn
}

output "gh_role_arn" {
  description = "IAM role ARN for infra-gh GitHub Actions."
  value       = aws_iam_role.github_actions["gh"].arn
}

output "iam_role_arn" {
  description = "IAM role ARN for infra-iam GitHub Actions."
  value       = aws_iam_role.github_actions["iam"].arn
}

output "vm_workloads_role_arn" {
  description = "IAM role ARN for infra-vm-workloads GitHub Actions."
  value       = aws_iam_role.github_actions["vm_workloads"].arn
}
