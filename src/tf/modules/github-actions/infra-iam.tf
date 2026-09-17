locals {
  iam_identity_store_resources = [
    "arn:aws:identitystore::${var.aws_account_id}:identitystore/${var.identity_store_id}",
    "arn:aws:identitystore:::user/*",
    "arn:aws:identitystore:::group/*",
    "arn:aws:identitystore:::membership/*",
  ]
}

resource "aws_iam_role_policy" "github_actions_iam" {
  name = "InfraIAMRepositoryAccess"
  role = aws_iam_role.github_actions["iam"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DiscoverIdentityCenter"
        Effect   = "Allow"
        Action   = "sso:ListInstances"
        Resource = "*"
      },
      {
        Sid    = "ReadIdentityStore"
        Effect = "Allow"
        Action = [
          "identitystore:DescribeGroup",
          "identitystore:DescribeGroupMembership",
          "identitystore:DescribeUser",
          "identitystore:GetGroupId",
          "identitystore:GetGroupMembershipId",
          "identitystore:GetUserId",
          "identitystore:ListGroupMemberships",
          "identitystore:ListGroupMembershipsForMember",
          "identitystore:ListGroups",
          "identitystore:ListUsers",
        ]
        Resource = local.iam_identity_store_resources
      },
      {
        Sid    = "ManageUsersAndMembershipsFromMain"
        Effect = "Allow"
        Action = [
          "identitystore:CreateGroupMembership",
          "identitystore:CreateUser",
          "identitystore:DeleteGroupMembership",
          "identitystore:DeleteUser",
          "identitystore:UpdateUser",
        ]
        Resource = local.iam_identity_store_resources
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
          }
        }
      },
    ]
  })
}
