variable "lz_aws_account_id" {
  description = "Verified LZ AWS account owning SGFDevsBootstrapTailnetParameterReader."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.lz_aws_account_id))
    error_message = "lz_aws_account_id must be the verified 12-digit LZ AWS account ID."
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}
