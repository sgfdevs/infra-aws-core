locals {
  ses_email_identities = toset([
    "methodconf.com",
    "sgf.dev",
  ])
}

resource "aws_sesv2_email_identity" "domain" {
  for_each = local.ses_email_identities

  email_identity = each.value

  tags = merge(
    var.tags,
    {
      ManagedBy = "OpenTofu"
    }
  )
}

resource "aws_sesv2_email_identity_mail_from_attributes" "domain" {
  for_each = aws_sesv2_email_identity.domain

  email_identity = each.value.email_identity

  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
  mail_from_domain       = "bounce.${each.value.email_identity}"
}
