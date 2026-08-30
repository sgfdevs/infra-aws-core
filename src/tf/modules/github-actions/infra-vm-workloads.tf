resource "aws_iam_role_policy" "github_actions_vm_workloads" {
  name = "InfraVMWorkloadsRepositoryAccess"
  role = aws_iam_role.github_actions["vm_workloads"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadWorkloadParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:ListTagsForResource",
        ]
        Resource = var.vm_workloads_parameter_arn
      },
      {
        Sid    = "ReadBootstrapParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
        ]
        Resource = var.vm_workloads_bootstrap_parameter_arns
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
          }
        }
      },
      {
        Sid      = "DescribeParameters"
        Effect   = "Allow"
        Action   = "ssm:DescribeParameters"
        Resource = "*"
      },
      {
        Sid    = "ManageWorkloadParametersFromMain"
        Effect = "Allow"
        Action = [
          "ssm:DeleteParameter",
          "ssm:PutParameter",
        ]
        Resource = var.vm_workloads_parameter_arn
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
          }
        }
      },
    ]
  })
}
