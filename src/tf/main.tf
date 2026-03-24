resource "aws_s3_bucket" "tfstate_state" {
  region = var.aws_region
  bucket = "sgfdevs-infra-tf-state"

  tags = merge(
    var.tags,
    {
      Name        = "sgfdevs-infra-tf-state"
      Environment = "global"
      ManagedBy   = "OpenTofu"
    }
  )
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

  tags = merge(
    var.tags,
    {
      Name        = "sgfdevs-infra-tflock"
      Environment = "global"
      ManagedBy   = "OpenTofu"
    }
  )
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = merge(
    var.tags,
    {
      Name        = "sgfdevs-github-actions-oidc"
      Environment = "global"
      ManagedBy   = "OpenTofu"
    }
  )
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
              "repo:sgfdevs/infra-vm-workloads:*",
              "repo:sgfdevs/infra-dns:*"
            ]
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "sgfdevs-github-actions-terraform-role"
      Environment = "global"
      ManagedBy   = "OpenTofu"
    }
  )
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
          "ssm:DescribeParameters"
        ]
        Resource = "*"
      }
    ]
  })
}
