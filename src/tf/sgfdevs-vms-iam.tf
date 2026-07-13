locals {
  sgfdevs_vms_name                       = "sgfdevs-vms"
  sgfdevs_vms_iam_user_name              = "${local.sgfdevs_vms_name}-eso-ssm"
  sgfdevs_vms_eso_access_key_id_path     = "/homelab/${local.sgfdevs_vms_name}/eso-ssm-access-key-id"
  sgfdevs_vms_eso_secret_access_key_path = "/homelab/${local.sgfdevs_vms_name}/eso-ssm-secret-access-key"
  sgfdevs_vms_parameter_path             = "/vm-workloads/sgfdevs/infra-vm-workloads/*"
}

data "aws_caller_identity" "sgfdevs_vms" {}

resource "aws_iam_user" "sgfdevs_vms_eso_ssm" {
  name = local.sgfdevs_vms_iam_user_name
}

resource "aws_iam_user_policy" "sgfdevs_vms_eso_ssm" {
  name = "${local.sgfdevs_vms_iam_user_name}-policy"
  user = aws_iam_user.sgfdevs_vms_eso_ssm.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SsmDenyBootstrapCredentials"
        Effect = "Deny"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.sgfdevs_vms.account_id}:parameter${local.sgfdevs_vms_eso_access_key_id_path}",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.sgfdevs_vms.account_id}:parameter${local.sgfdevs_vms_eso_secret_access_key_path}"
        ]
      },
      {
        Sid    = "SsmReadSgfdevsWorkloads"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.sgfdevs_vms.account_id}:parameter${local.sgfdevs_vms_parameter_path}"
      }
    ]
  })
}

resource "aws_iam_access_key" "sgfdevs_vms_eso_ssm" {
  user = aws_iam_user.sgfdevs_vms_eso_ssm.name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssm_parameter" "sgfdevs_vms_eso_access_key_id" {
  name             = local.sgfdevs_vms_eso_access_key_id_path
  type             = "SecureString"
  value_wo         = aws_iam_access_key.sgfdevs_vms_eso_ssm.id
  value_wo_version = 1

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssm_parameter" "sgfdevs_vms_eso_secret_access_key" {
  name             = local.sgfdevs_vms_eso_secret_access_key_path
  type             = "SecureString"
  value_wo         = aws_iam_access_key.sgfdevs_vms_eso_ssm.secret
  value_wo_version = 1

  lifecycle {
    prevent_destroy = true
  }
}
