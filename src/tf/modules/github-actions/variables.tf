variable "application_ses_policy_arns" {
  description = "SES sender policy ARNs keyed by application."
  type        = map(string)
}

variable "application_ses_senders" {
  description = "Application SES sender configuration."
  type = map(object({
    domain      = string
    path        = string
    policy_name = string
  }))
}

variable "aws_account_id" {
  description = "AWS account containing the repository-managed resources."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  type        = string
}

variable "ses_identity_arns" {
  description = "ARNs of the SES identities read by infra-dns."
  type        = list(string)
}

variable "sgfdevs_k3s_application_s3_workload_boundary_arn" {
  description = "Permissions boundary ARN for application-managed Kubernetes S3 workload roles."
  type        = string
}

variable "sgfdevs_k3s_oidc_provider_arn" {
  description = "ARN of the Kubernetes OIDC provider for the SGF Devs K3s cluster."
  type        = string
}

variable "sgfdevs_k3s_workload_boundary_arn" {
  description = "Permissions boundary ARN for SGF Devs K3s Kubernetes workload roles."
  type        = string
}

variable "state_bucket_arn" {
  description = "ARN of the shared OpenTofu state bucket."
  type        = string
}

variable "state_bucket_name" {
  description = "Name of the shared OpenTofu state bucket."
  type        = string
}

variable "state_lock_table_arn" {
  description = "ARN of the shared OpenTofu state lock table."
  type        = string
}

variable "vm_workloads_parameter_arn" {
  description = "ARN pattern for parameters managed by infra-vm-workloads."
  type        = string
}
