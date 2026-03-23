variable "tags" {
  description = "Extra tags for backend resources."
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}
