resource "aws_iam_role_policy" "github_actions_dns" {
  name = "InfraDNSRepositoryAccess"
  role = aws_iam_role.github_actions["dns"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSESIdentities"
        Effect = "Allow"
        Action = [
          "ses:GetEmailIdentity",
          "ses:ListTagsForResource",
        ]
        Resource = var.ses_identity_arns
      },
    ]
  })
}
