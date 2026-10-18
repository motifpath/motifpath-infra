# A role GitHub Actions assumes with its OIDC token; no static keys exist.
resource "aws_iam_role" "this" {
  name                 = var.name
  max_session_duration = 3600
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = var.subjects }
      }
    }]
  })
}

resource "aws_iam_role_policy" "this" {
  name   = var.name
  role   = aws_iam_role.this.name
  policy = var.policy_json
}
