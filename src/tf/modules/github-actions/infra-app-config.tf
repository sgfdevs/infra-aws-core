resource "aws_iam_role_policy" "github_actions_app_config" {
  name = "InfraAppConfigRepositoryAccess"
  role = aws_iam_role.github_actions["app_config"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
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
