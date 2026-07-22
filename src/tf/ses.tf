locals {
  ses_email_identities = toset([
    "methodconf.com",
    "sgf.dev",
  ])
}

resource "aws_sesv2_account_vdm_attributes" "current" {
  vdm_enabled = "ENABLED"

  dashboard_attributes {
    engagement_metrics = "DISABLED"
  }

  guardian_attributes {
    optimized_shared_delivery = "DISABLED"
  }
}

resource "aws_sesv2_configuration_set" "transactional" {
  configuration_set_name = "transactional"

  vdm_options {
    dashboard_options {
      engagement_metrics = "DISABLED"
    }

    guardian_options {
      optimized_shared_delivery = "DISABLED"
    }
  }

  tags = {
    ManagedBy = "OpenTofu"
  }

  depends_on = [aws_sesv2_account_vdm_attributes.current]
}

resource "aws_sesv2_email_identity" "domain" {
  for_each = local.ses_email_identities

  email_identity         = each.value
  configuration_set_name = aws_sesv2_configuration_set.transactional.configuration_set_name

  tags = {
    ManagedBy = "OpenTofu"
  }
}

resource "aws_sesv2_email_identity_mail_from_attributes" "domain" {
  for_each = aws_sesv2_email_identity.domain

  email_identity = each.value.email_identity

  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
  mail_from_domain       = "bounce.${each.value.email_identity}"
}
