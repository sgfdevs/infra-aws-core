resource "aws_iam_openid_connect_provider" "sgfdevs_k3s" {
  url = "https://k8s-oidc.sgf.dev"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Environment = "global"
    ManagedBy   = "OpenTofu"
    Name        = "sgfdevs-k3s-oidc"
    Repository  = "sgfdevs/infra-vm-workloads"
  }
}

resource "aws_iam_policy" "sgfdevs_k3s_kubernetes_workload_boundary" {
  name        = "SGFDevsK3sKubernetesWorkloadBoundary"
  path        = "/sgfdevs-k3s/"
  description = "Require SGF Devs K3s workload roles to be used only by Kubernetes service accounts"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowWorkloadPermissions"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      {
        Sid      = "DenyOtherFederatedProviders"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          ArnNotEquals = {
            "aws:FederatedProvider" = aws_iam_openid_connect_provider.sgfdevs_k3s.arn
          }
        }
      },
      {
        Sid      = "DenyNonServiceAccountSubjects"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotLike = {
            "k8s-oidc.sgf.dev:sub" = "system:serviceaccount:*:*"
          }
        }
      },
      {
        Sid      = "DenyUnexpectedAudience"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "k8s-oidc.sgf.dev:aud" = "sts.amazonaws.com"
          }
        }
      },
      {
        Sid    = "DenyPrivilegeEscalation"
        Effect = "Deny"
        Action = [
          "account:*",
          "iam:*",
          "identitystore:*",
          "organizations:*",
          "sso:*",
          "sso-directory:*",
          "sts:AssumeRole",
          "sts:AssumeRoleWithSAML",
          "sts:AssumeRoleWithWebIdentity",
          "sts:GetFederationToken",
          "sts:GetSessionToken",
        ]
        Resource = "*"
      },
    ]
  })

  tags = {
    Environment = "global"
    ManagedBy   = "OpenTofu"
    Name        = "sgfdevs-k3s-kubernetes-workload-boundary"
  }
}

resource "aws_iam_policy" "sgfdevs_k3s_application_s3_workload_boundary" {
  name        = "SGFDevsK3sApplicationS3WorkloadBoundary"
  path        = "/sgfdevs-k3s/"
  description = "Limit application-managed Kubernetes workload roles to S3 data access outside Terraform state"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3DataAccess"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectAttributes",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyTerraformStateAccess"
        Effect = "Deny"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.tfstate_state.arn,
          "${aws_s3_bucket.tfstate_state.arn}/*",
        ]
      },
      {
        Sid      = "DenyOtherFederatedProviders"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          ArnNotEquals = {
            "aws:FederatedProvider" = aws_iam_openid_connect_provider.sgfdevs_k3s.arn
          }
        }
      },
      {
        Sid      = "DenyNonServiceAccountSubjects"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotLike = {
            "k8s-oidc.sgf.dev:sub" = "system:serviceaccount:*:*"
          }
        }
      },
      {
        Sid      = "DenyUnexpectedAudience"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "k8s-oidc.sgf.dev:aud" = "sts.amazonaws.com"
          }
        }
      },
    ]
  })

  tags = {
    Environment = "global"
    ManagedBy   = "OpenTofu"
    Name        = "sgfdevs-k3s-application-s3-workload-boundary"
  }
}
