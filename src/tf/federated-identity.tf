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
