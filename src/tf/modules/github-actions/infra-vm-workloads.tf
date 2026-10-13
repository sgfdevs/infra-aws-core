locals {
  vm_workloads_workload_role_arn_pattern = "arn:aws:iam::${var.aws_account_id}:role/sgfdevs-k3s/*"
}

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
        Sid      = "DescribeParameters"
        Effect   = "Allow"
        Action   = "ssm:DescribeParameters"
        Resource = "*"
      },
      {
        Sid    = "ReadSGFDevsK3sOIDCProvider"
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviderTags",
        ]
        Resource = var.sgfdevs_k3s_oidc_provider_arn
      },
      {
        Sid    = "ReadSGFDevsK3sWorkloadRole"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoleTags",
        ]
        Resource = local.vm_workloads_workload_role_arn_pattern
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
      {
        Sid      = "CreateSGFDevsK3sWorkloadRoleFromMain"
        Effect   = "Allow"
        Action   = "iam:CreateRole"
        Resource = local.vm_workloads_workload_role_arn_pattern
        Condition = {
          StringEquals = {
            "iam:PermissionsBoundary"                 = var.sgfdevs_k3s_workload_boundary_arn
            "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
          }
        }
      },
      {
        Sid    = "ManageSGFDevsK3sWorkloadRoleTagsFromMain"
        Effect = "Allow"
        Action = [
          "iam:TagRole",
          "iam:UntagRole",
        ]
        Resource = local.vm_workloads_workload_role_arn_pattern
        Condition = {
          "ForAllValues:StringEquals" = {
            "aws:TagKeys" = [
              "KubernetesNamespace",
              "KubernetesServiceAccount",
              "ManagedBy",
              "Repository",
            ]
          }
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
          }
          StringEqualsIfExists = {
            "aws:RequestTag/ManagedBy"  = "OpenTofu"
            "aws:RequestTag/Repository" = "sgfdevs/infra-vm-workloads"
          }
        }
      },
      {
        Sid    = "ManageBoundedSGFDevsK3sWorkloadRoleFromMain"
        Effect = "Allow"
        Action = [
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:PutRolePermissionsBoundary",
          "iam:PutRolePolicy",
          "iam:UpdateAssumeRolePolicy",
          "iam:UpdateRole",
        ]
        Resource = local.vm_workloads_workload_role_arn_pattern
        Condition = {
          StringEquals = {
            "iam:PermissionsBoundary"                 = var.sgfdevs_k3s_workload_boundary_arn
            "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
          }
        }
      },
    ]
  })
}
