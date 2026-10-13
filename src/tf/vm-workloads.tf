resource "aws_iam_policy" "vm_workloads_parameter_reader_boundary" {
  name        = "VMWorkloadsParameterReaderBoundary"
  path        = "/vm-workloads/sgfdevs/"
  description = "Limit repository-owned parameter readers to the VM workload parameter prefix"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadRepositoryParameters"
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/vm-workloads/sgfdevs/infra-vm-workloads/*"
      },
    ]
  })
}
