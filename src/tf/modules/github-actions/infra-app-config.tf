data "aws_region" "current" {}

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
          Sid    = "ReadApplicationBucketConfiguration"
          Effect = "Allow"
          Action = [
            "s3:GetAccelerateConfiguration",
            "s3:GetBucket*",
            "s3:GetEncryptionConfiguration",
            "s3:GetLifecycleConfiguration",
            "s3:GetObjectLockConfiguration",
            "s3:GetReplicationConfiguration",
            "s3:ListBucket",
          ]
          NotResource = var.state_bucket_arn
        },
        {
          Sid    = "ManageApplicationBucketsFromMain"
          Effect = "Allow"
          Action = [
            "s3:CreateBucket",
            "s3:DeleteBucket",
            "s3:DeleteBucket*",
            "s3:PutBucket*",
            "s3:PutEncryptionConfiguration",
          ]
          NotResource = var.state_bucket_arn
          Condition = {
            StringEquals = {
              "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
            }
          }
        },
        {
          Sid    = "DenyApplicationObjectAccess"
          Effect = "Deny"
          Action = [
            "s3:AbortMultipartUpload",
            "s3:DeleteObject*",
            "s3:GetObject*",
            "s3:PutObject*",
            "s3:RestoreObject",
            "s3:SelectObjectContent",
          ]
          NotResource = "${var.state_bucket_arn}/*"
        },
        {
          Sid    = "DenyUsingProvisionedRoles"
          Effect = "Deny"
          Action = [
            "iam:PassRole",
            "sts:AssumeRole",
          ]
          Resource = "*"
        },
        {
          Sid    = "ReadApplicationWorkloadRoles"
          Effect = "Allow"
          Action = [
            "iam:GetRole",
            "iam:GetRolePolicy",
            "iam:ListAttachedRolePolicies",
            "iam:ListInstanceProfilesForRole",
            "iam:ListRolePolicies",
            "iam:ListRoleTags",
          ]
          Resource = "arn:aws:iam::${var.aws_account_id}:role/*"
          Condition = {
            StringEquals = {
              "aws:ResourceTag/ManagedBy"  = "OpenTofu"
              "aws:ResourceTag/Repository" = "sgfdevs/infra-app-config"
            }
          }
        },
        {
          Sid      = "CreateApplicationWorkloadRolesFromMain"
          Effect   = "Allow"
          Action   = "iam:CreateRole"
          Resource = "arn:aws:iam::${var.aws_account_id}:role/*"
          Condition = {
            Null = {
              "aws:RequestTag/KubernetesNamespace"      = "false"
              "aws:RequestTag/KubernetesServiceAccount" = "false"
            }
            StringEquals = {
              "aws:RequestTag/ManagedBy"                = "OpenTofu"
              "aws:RequestTag/Repository"               = "sgfdevs/infra-app-config"
              "iam:PermissionsBoundary"                 = var.sgfdevs_k3s_application_s3_workload_boundary_arn
              "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
            }
          }
        },
        {
          Sid      = "TagApplicationWorkloadRolesOnCreate"
          Effect   = "Allow"
          Action   = "iam:TagRole"
          Resource = "arn:aws:iam::${var.aws_account_id}:role/*"
          Condition = {
            StringEquals = {
              "aws:RequestTag/ManagedBy"                = "OpenTofu"
              "aws:RequestTag/Repository"               = "sgfdevs/infra-app-config"
              "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
            }
          }
        },
        {
          Sid    = "ManageApplicationWorkloadRoleTagsFromMain"
          Effect = "Allow"
          Action = [
            "iam:TagRole",
            "iam:UntagRole",
          ]
          Resource = "arn:aws:iam::${var.aws_account_id}:role/*"
          Condition = {
            StringEquals = {
              "aws:ResourceTag/ManagedBy"               = "OpenTofu"
              "aws:ResourceTag/Repository"              = "sgfdevs/infra-app-config"
              "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
            }
          }
        },
        {
          Sid    = "ManageApplicationWorkloadRolesFromMain"
          Effect = "Allow"
          Action = [
            "iam:DeleteRole",
            "iam:DeleteRolePolicy",
            "iam:PutRolePermissionsBoundary",
            "iam:PutRolePolicy",
            "iam:UpdateAssumeRolePolicy",
            "iam:UpdateRole",
          ]
          Resource = "arn:aws:iam::${var.aws_account_id}:role/*"
          Condition = {
            StringEquals = {
              "aws:ResourceTag/ManagedBy"               = "OpenTofu"
              "aws:ResourceTag/Repository"              = "sgfdevs/infra-app-config"
              "iam:PermissionsBoundary"                 = var.sgfdevs_k3s_application_s3_workload_boundary_arn
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
