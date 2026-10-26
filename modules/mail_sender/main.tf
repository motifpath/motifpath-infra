# The domain one environment sends its own email from, verified with SES, and
# the only credentials allowed to send from it. Services reach SES over SMTP
# with this user's derived SMTP password, since containers cannot use the
# instance role.

data "aws_region" "current" {}

locals {
  mail_from_domain = "bounce.${var.domain}"
  region           = data.aws_region.current.region
  # SES always issues three DKIM tokens for Easy DKIM; the keys are fixed so
  # the records can be planned before the tokens are known.
  dkim_keys = toset(["0", "1", "2"])
}

resource "aws_sesv2_email_identity" "this" {
  email_identity = var.domain
}

# A custom MAIL FROM domain makes the envelope sender a subdomain of the
# sending domain, so SPF aligns with the From address and mail passes a strict
# DMARC policy on SPF as well as on DKIM.
resource "aws_sesv2_email_identity_mail_from_attributes" "this" {
  email_identity         = aws_sesv2_email_identity.this.email_identity
  mail_from_domain       = local.mail_from_domain
  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
}

module "records" {
  source = "../dns_records"

  zone_id = var.zone_id
  records = merge(
    {
      for key in local.dkim_keys : "dkim${key}" => {
        name   = "${aws_sesv2_email_identity.this.dkim_signing_attributes[0].tokens[tonumber(key)]}._domainkey.${var.domain}"
        type   = "CNAME"
        values = ["${aws_sesv2_email_identity.this.dkim_signing_attributes[0].tokens[tonumber(key)]}.dkim.amazonses.com"]
      }
    },
    {
      mail_from_mx  = { name = local.mail_from_domain, type = "MX", values = ["10 feedback-smtp.${local.region}.amazonses.com"] }
      mail_from_spf = { name = local.mail_from_domain, type = "TXT", values = ["v=spf1 include:amazonses.com ~all"] }
    },
  )
}

resource "aws_iam_user" "this" {
  name = var.user_name
}

resource "aws_iam_user_policy" "this" {
  name = var.user_name
  user = aws_iam_user.this.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SendFromThisDomainOnly"
        Effect   = "Allow"
        Action   = "ses:SendRawEmail"
        Resource = aws_sesv2_email_identity.this.arn
        Condition = merge(
          {
            StringLike = { "ses:FromAddress" = "*@${var.domain}" }
          },
          # When an allow-list is given, every recipient of a message must
          # match it, so a non-production environment can never mail a real
          # user even after the account leaves the SES sandbox.
          var.allowed_recipients == null ? {} : {
            "ForAllValues:StringLike" = { "ses:Recipients" = var.allowed_recipients }
          },
        )
      },
    ]
  })
}

# Rotate by replacing it: terraform apply -replace=<address of this key>,
# then redeploy so the services pick up the new SMTP password.
resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}
