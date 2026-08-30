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

locals {
  application_ses_senders = {
    methodconf = {
      domain      = "methodconf.com"
      path        = "methodconf"
      policy_name = "MethodConfSESSender"
    }
    sgf_dev = {
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
  description = "Allow ${each.value.domain} applications to send email from their tagged address"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = [
          aws_sesv2_email_identity.domain[each.value.domain].arn,
          aws_sesv2_configuration_set.transactional.arn,
        ]
        Condition = {
          StringEquals = {
            "ses:FromAddress" = "$${aws:PrincipalTag/SESFromAddress}"
          }
        }
      }
    ]
  })
}
