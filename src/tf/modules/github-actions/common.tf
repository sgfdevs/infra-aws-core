locals {
  repositories = {
    app_config = {
      github_subject = "repo:sgfdevs@53604170/infra-app-config@1298907442"
      repository     = "sgfdevs/infra-app-config"
      role_name      = "GitHubActionsInfraAppConfigRole"
      state_key      = "sgfdevs-infra-app-config/terraform.tfstate"
      state_prefix   = "sgfdevs-infra-app-config"
    }
    dns = {
      github_subject = "repo:sgfdevs@53604170/infra-dns@1191039220"
      repository     = "sgfdevs/infra-dns"
      role_name      = "GitHubActionsInfraDNSRole"
      state_key      = "sgfdevs-infra-dns/terraform.tfstate"
      state_prefix   = "sgfdevs-infra-dns"
    }
    gh = {
      github_subject = "repo:sgfdevs@53604170/infra-gh@1331469226"
      repository     = "sgfdevs/infra-gh"
      role_name      = "GitHubActionsInfraGHRole"
      state_key      = "sgfdevs/infra-gh/terraform.tfstate"
      state_prefix   = "sgfdevs/infra-gh"
    }
    iam = {
      github_subject = "repo:sgfdevs@53604170/infra-iam@1354768312"
      repository     = "sgfdevs/infra-iam"
      role_name      = "GitHubActionsInfraIAMRole"
      state_key      = "sgfdevs-infra-iam/terraform.tfstate"
      state_prefix   = "sgfdevs-infra-iam"
    }
    vm_workloads = {
      github_subject = "repo:sgfdevs@53604170/infra-vm-workloads@1189754282"
      repository     = "sgfdevs/infra-vm-workloads"
      role_name      = "GitHubActionsInfraVMWorkloadsRole"
      state_key      = "sgfdevs-vm-workloads/terraform.tfstate"
      state_prefix   = "sgfdevs-vm-workloads"
    }
  }
}

resource "aws_iam_role" "github_actions" {
  for_each = local.repositories

  name = each.value.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = [
              "${each.value.github_subject}:ref:refs/heads/main",
              "${each.value.github_subject}:pull_request",
            ]
          }
        }
      }
    ]
  })

  tags = {
    Environment          = "global"
    GitHubMainSubject    = "${each.value.github_subject}:ref:refs/heads/main"
    ManagedBy            = "OpenTofu"
    Name                 = "sgfdevs-github-actions-infra-${replace(each.key, "_", "-")}-role"
    Repository           = each.value.repository
    TerraformStateKey    = each.value.state_key
    TerraformStatePrefix = each.value.state_prefix
  }
}

resource "aws_iam_policy" "terraform_state_access" {
  name        = "GitHubActionsTerraformStateAccess"
  description = "Repository-scoped OpenTofu state access derived from IAM role tags"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadStateBucketMetadata"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
        ]
        Resource = var.state_bucket_arn
      },
      {
        Sid      = "ListRepositoryState"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = var.state_bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "$${aws:PrincipalTag/TerraformStatePrefix}",
              "$${aws:PrincipalTag/TerraformStatePrefix}/*",
            ]
          }
        }
      },
      {
        Sid      = "ReadRepositoryState"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${var.state_bucket_arn}/$${aws:PrincipalTag/TerraformStateKey}"
      },
      {
        Sid      = "DescribeStateLockTable"
        Effect   = "Allow"
        Action   = "dynamodb:DescribeTable"
        Resource = var.state_lock_table_arn
      },
      {
        Sid    = "ManageRepositoryStateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
        ]
        Resource = var.state_lock_table_arn
        Condition = {
          "ForAllValues:StringEquals" = {
            "dynamodb:LeadingKeys" = "${var.state_bucket_name}/$${aws:PrincipalTag/TerraformStateKey}"
          }
        }
      },
      {
        Sid      = "ReadRepositoryStateChecksum"
        Effect   = "Allow"
        Action   = "dynamodb:GetItem"
        Resource = var.state_lock_table_arn
        Condition = {
          "ForAllValues:StringEquals" = {
            "dynamodb:LeadingKeys" = "${var.state_bucket_name}/$${aws:PrincipalTag/TerraformStateKey}-md5"
          }
        }
      },
      {
        Sid      = "WriteRepositoryStateFromMain"
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${var.state_bucket_arn}/$${aws:PrincipalTag/TerraformStateKey}"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
          }
        }
      },
      {
        Sid      = "WriteRepositoryStateChecksumFromMain"
        Effect   = "Allow"
        Action   = "dynamodb:PutItem"
        Resource = var.state_lock_table_arn
        Condition = {
          "ForAllValues:StringEquals" = {
            "dynamodb:LeadingKeys" = "${var.state_bucket_name}/$${aws:PrincipalTag/TerraformStateKey}-md5"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
          }
        }
      },
    ]
  })

  tags = {
    Environment = "global"
    ManagedBy   = "OpenTofu"
    Name        = "sgfdevs-github-actions-terraform-state-access"
  }
}

resource "aws_iam_role_policy_attachment" "terraform_state_access" {
  for_each = local.repositories

  role       = aws_iam_role.github_actions[each.key].name
  policy_arn = aws_iam_policy.terraform_state_access.arn
}
