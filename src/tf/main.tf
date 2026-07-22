resource "aws_s3_bucket" "tfstate_state" {
  region = var.aws_region
  bucket = "sgfdevs-infra-tf-state"

  tags = {
    Name        = "sgfdevs-infra-tf-state"
    Environment = "global"
    ManagedBy   = "OpenTofu"
  }
}

resource "aws_s3_bucket_versioning" "tfstate_state" {
  region = var.aws_region
  bucket = aws_s3_bucket.tfstate_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_state" {
  region = var.aws_region
  bucket = aws_s3_bucket.tfstate_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_state" {
  region = var.aws_region
  bucket = aws_s3_bucket.tfstate_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "tfstate_state" {
  region = var.aws_region
  bucket = aws_s3_bucket.tfstate_state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_dynamodb_table" "tflock_state" {
  region       = var.aws_region
  name         = "sgfdevs-infra-tflock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "sgfdevs-infra-tflock"
    Environment = "global"
    ManagedBy   = "OpenTofu"
  }
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name        = "sgfdevs-github-actions-oidc"
    Environment = "global"
    ManagedBy   = "OpenTofu"
  }
}

resource "aws_iam_role" "github_actions_terraform" {
  name = "GitHubActionsTerraformRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:sgfdevs@53604170/infra-vm-workloads@1189754282:*",
              "repo:sgfdevs@53604170/infra-dns@1191039220:*",
              "repo:sgfdevs@53604170/infra-app-config@1298907442:*"
            ]
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "sgfdevs-github-actions-terraform-role"
    Environment = "global"
    ManagedBy   = "OpenTofu"
  }
}

resource "aws_iam_role_policy" "github_actions_terraform_state" {
  name = "TerraformStateAccessPolicy"
  role = aws_iam_role.github_actions_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.tfstate_state.arn,
          "${aws_s3_bucket.tfstate_state.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = aws_dynamodb_table.tflock_state.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_terraform_ssm" {
  name = "VmWorkloadsSSMParameterAccessPolicy"
  role = aws_iam_role.github_actions_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:PutParameter",
          "ssm:DeleteParameter",
          "ssm:ListTagsForResource"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/vm-workloads/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.sgfdevs_vms.account_id}:parameter${local.sgfdevs_vms_eso_access_key_id_path}",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.sgfdevs_vms.account_id}:parameter${local.sgfdevs_vms_eso_secret_access_key_path}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeParameters"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_terraform_ses" {
  name = "SESEmailIdentityReadPolicy"
  role = aws_iam_role.github_actions_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:GetEmailIdentity",
          "ses:ListTagsForResource"
        ]
        Resource = [for identity in aws_sesv2_email_identity.domain : identity.arn]
      }
    ]
  })
}

locals {
  application_ses_senders = {
    methodconf = {
      application = "methodconf.com"
      domain      = "methodconf.com"
      path        = "methodconf"
      policy_name = "MethodConfSESSender"
    }
    sgf_dev = {
      application = "sgf.dev"
      domain      = "sgf.dev"
      path        = "sgf-dev"
      policy_name = "SgfDevSESSender"
    }
  }
  application_ses_policy_arns = {
    for key, application in local.application_ses_senders :
    key => "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/applications/${application.path}/${application.policy_name}"
  }
}

resource "aws_iam_policy" "application_ses_sender" {
  for_each = local.application_ses_senders

  name        = each.value.policy_name
  path        = "/applications/${each.value.path}/"
  description = "Allow ${each.value.application} applications to send email from their tagged address"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = aws_sesv2_email_identity.domain[each.value.domain].arn
        Condition = {
          StringEquals = {
            "ses:FromAddress" = "$${aws:PrincipalTag/SESFromAddress}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_terraform_application_ses_iam" {
  name = "ApplicationSESCredentialAccessPolicy"
  role = aws_iam_role.github_actions_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [for key, application in local.application_ses_senders : {
        Sid      = "Create${replace(title(key), "_", "")}SESUsers"
        Effect   = "Allow"
        Action   = "iam:CreateUser"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/applications/${application.path}/*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/Application" = application.application
            "aws:RequestTag/ManagedBy"   = "OpenTofu"
          }
          StringLike = {
            "aws:RequestTag/SESFromAddress" = "*@${application.domain}"
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
      [for key, application in local.application_ses_senders : {
        Sid    = "AttachOnly${replace(title(key), "_", "")}SESPolicy"
        Effect = "Allow"
        Action = [
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/applications/${application.path}/*"
        Condition = {
          ArnEquals = {
            "iam:PolicyARN" = local.application_ses_policy_arns[key]
          }
          StringEquals = {
            "iam:ResourceTag/Application" = application.application
            "iam:ResourceTag/ManagedBy"   = "OpenTofu"
          }
          StringLike = {
            "iam:ResourceTag/SESFromAddress" = "*@${application.domain}"
          }
        }
      }],
      [for key, application in local.application_ses_senders : {
        Sid    = "Manage${replace(title(key), "_", "")}SESUsers"
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:DeleteUser",
          "iam:GetAccessKeyLastUsed",
          "iam:GetUser",
          "iam:ListAccessKeys",
          "iam:ListAttachedUserPolicies",
          "iam:ListUserTags",
          "iam:TagUser",
          "iam:UntagUser",
          "iam:UpdateAccessKey"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/applications/${application.path}/*"
        Condition = {
          StringEquals = {
            "iam:ResourceTag/Application" = application.application
            "iam:ResourceTag/ManagedBy"   = "OpenTofu"
          }
          StringLike = {
            "iam:ResourceTag/SESFromAddress" = "*@${application.domain}"
          }
        }
      }],
      [for key, application in local.application_ses_senders : {
        Sid      = "RejectInvalid${replace(title(key), "_", "")}SenderTags"
        Effect   = "Deny"
        Action   = "iam:TagUser"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/applications/${application.path}/*"
        Condition = {
          Null = {
            "aws:RequestTag/SESFromAddress" = "false"
          }
          StringNotLike = {
            "aws:RequestTag/SESFromAddress" = "*@${application.domain}"
          }
        }
      }],
      [for key, application in local.application_ses_senders : {
        Sid      = "RejectInvalid${replace(title(key), "_", "")}ApplicationTags"
        Effect   = "Deny"
        Action   = "iam:TagUser"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/applications/${application.path}/*"
        Condition = {
          Null = {
            "aws:RequestTag/Application" = "false"
          }
          StringNotEquals = {
            "aws:RequestTag/Application" = application.application
          }
        }
      }]
    )
  })
}
