data "aws_region" "current" {}

locals {
  app_config_kaneo_bucket_arn        = "arn:aws:s3:::sgfdevs-kaneo-assets"
  app_config_kaneo_workload_role_arn = "arn:aws:iam::${var.aws_account_id}:role/sgfdevs-k3s/sgfdevs-k3s-kaneo"
}

resource "aws_iam_role_policy" "github_actions_app_config" {
  name = "InfraAppConfigRepositoryAccess"
  role = aws_iam_role.github_actions["app_config"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid      = "ReadDexOpenBaoClientSecret"
          Effect   = "Allow"
          Action   = "ssm:GetParameter"
          Resource = "arn:aws:ssm:${data.aws_region.current.region}:${var.aws_account_id}:parameter/vm-workloads/sgfdevs/infra-vm-workloads/dex-openbao-client-secret"
        },
        {
          Sid    = "ReadKaneoBucketConfiguration"
          Effect = "Allow"
          Action = [
            "s3:Get*",
            "s3:ListBucket",
          ]
          Resource = local.app_config_kaneo_bucket_arn
        },
        {
          Sid    = "ManageKaneoBucketFromMain"
          Effect = "Allow"
          Action = [
            "s3:CreateBucket",
            "s3:DeleteBucket",
            "s3:DeleteBucket*",
            "s3:DeleteEncryptionConfiguration",
            "s3:PutBucket*",
            "s3:PutEncryptionConfiguration",
          ]
          Resource = local.app_config_kaneo_bucket_arn
          Condition = {
            StringEquals = {
              "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
            }
          }
        },
        {
          Sid    = "ReadKaneoWorkloadRole"
          Effect = "Allow"
          Action = [
            "iam:GetRole",
            "iam:GetRolePolicy",
            "iam:ListAttachedRolePolicies",
            "iam:ListInstanceProfilesForRole",
            "iam:ListRolePolicies",
            "iam:ListRoleTags",
          ]
          Resource = local.app_config_kaneo_workload_role_arn
        },
        {
          Sid      = "CreateKaneoWorkloadRoleFromMain"
          Effect   = "Allow"
          Action   = "iam:CreateRole"
          Resource = local.app_config_kaneo_workload_role_arn
          Condition = {
            StringEquals = {
              "aws:RequestTag/KubernetesNamespace"      = "kaneo"
              "aws:RequestTag/KubernetesServiceAccount" = "kaneo-secrets"
              "aws:RequestTag/ManagedBy"                = "OpenTofu"
              "aws:RequestTag/Repository"               = "sgfdevs/infra-app-config"
              "iam:PermissionsBoundary"                 = var.sgfdevs_k3s_workload_boundary_arn
              "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
            }
            "ForAllValues:StringEquals" = {
              "aws:TagKeys" = [
                "KubernetesNamespace",
                "KubernetesServiceAccount",
                "ManagedBy",
                "Repository",
              ]
            }
          }
        },
        {
          Sid    = "ManageKaneoWorkloadRoleTagsFromMain"
          Effect = "Allow"
          Action = [
            "iam:TagRole",
            "iam:UntagRole",
          ]
          Resource = local.app_config_kaneo_workload_role_arn
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
              "aws:RequestTag/KubernetesNamespace"      = "kaneo"
              "aws:RequestTag/KubernetesServiceAccount" = "kaneo-secrets"
              "aws:RequestTag/ManagedBy"                = "OpenTofu"
              "aws:RequestTag/Repository"               = "sgfdevs/infra-app-config"
            }
          }
        },
        {
          Sid    = "ManageBoundedKaneoWorkloadRoleFromMain"
          Effect = "Allow"
          Action = [
            "iam:DeleteRole",
            "iam:DeleteRolePolicy",
            "iam:PutRolePermissionsBoundary",
            "iam:PutRolePolicy",
            "iam:UpdateAssumeRolePolicy",
            "iam:UpdateRole",
          ]
          Resource = local.app_config_kaneo_workload_role_arn
          Condition = {
            StringEquals = {
              "iam:PermissionsBoundary"                 = var.sgfdevs_k3s_workload_boundary_arn
              "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
            }
          }
        },
      ],
      [for key, application in var.application_ses_senders : {
        Sid      = "Create${replace(title(key), "_", "")}SESUsers"
        Effect   = "Allow"
        Action   = "iam:CreateUser"
        Resource = "arn:aws:iam::${var.aws_account_id}:user/applications/${application.path}/*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/ManagedBy"                = "OpenTofu"
            "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
          }
          StringLike = {
            "aws:RequestTag/SESFromAddress" = "*@${application.domain}"
          }
          Null = {
            "aws:RequestTag/Application" = "false"
          }
          "ForAllValues:StringEquals" = {
            "aws:TagKeys" = [
              "Application",
              "Environment",
              "ManagedBy",
              "SESFromAddress",
            ]
          }
        }
      }],
      [for key, application in var.application_ses_senders : {
        Sid    = "AttachOnly${replace(title(key), "_", "")}SESPolicy"
        Effect = "Allow"
        Action = [
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy"
        ]
        Resource = "arn:aws:iam::${var.aws_account_id}:user/applications/${application.path}/*"
        Condition = {
          ArnEquals = {
            "iam:PolicyARN" = var.application_ses_policy_arns[key]
          }
          StringEquals = {
            "iam:ResourceTag/ManagedBy"               = "OpenTofu"
            "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
          }
          StringLike = {
            "iam:ResourceTag/SESFromAddress" = "*@${application.domain}"
          }
          Null = {
            "iam:ResourceTag/Application" = "false"
          }
        }
      }],
      [for key, application in var.application_ses_senders : {
        Sid    = "Read${replace(title(key), "_", "")}SESUsers"
        Effect = "Allow"
        Action = [
          "iam:GetAccessKeyLastUsed",
          "iam:GetUser",
          "iam:ListAccessKeys",
          "iam:ListAttachedUserPolicies",
          "iam:ListGroupsForUser",
          "iam:ListUserTags",
        ]
        Resource = "arn:aws:iam::${var.aws_account_id}:user/applications/${application.path}/*"
        Condition = {
          StringEquals = {
            "iam:ResourceTag/ManagedBy" = "OpenTofu"
          }
          StringLike = {
            "iam:ResourceTag/SESFromAddress" = "*@${application.domain}"
          }
          Null = {
            "iam:ResourceTag/Application" = "false"
          }
        }
      }],
      [for key, application in var.application_ses_senders : {
        Sid    = "Manage${replace(title(key), "_", "")}SESUsers"
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:DeleteUser",
          "iam:TagUser",
          "iam:UntagUser",
          "iam:UpdateAccessKey",
          "iam:UpdateUser",
        ]
        Resource = "arn:aws:iam::${var.aws_account_id}:user/applications/${application.path}/*"
        Condition = {
          StringEquals = {
            "iam:ResourceTag/ManagedBy"               = "OpenTofu"
            "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
          }
          StringLike = {
            "iam:ResourceTag/SESFromAddress" = "*@${application.domain}"
          }
          Null = {
            "iam:ResourceTag/Application" = "false"
          }
        }
      }],
      [for key, application in var.application_ses_senders : {
        Sid      = "RejectInvalid${replace(title(key), "_", "")}SenderTags"
        Effect   = "Deny"
        Action   = "iam:TagUser"
        Resource = "arn:aws:iam::${var.aws_account_id}:user/applications/${application.path}/*"
        Condition = {
          Null = {
            "aws:RequestTag/SESFromAddress" = "false"
          }
          StringNotLike = {
            "aws:RequestTag/SESFromAddress" = "*@${application.domain}"
          }
        }
      }],
    )
  })
}
