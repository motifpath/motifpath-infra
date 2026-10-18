# An IAM user one CI job signs in as, with a key stored as a GitHub
# environment secret. The account does not allow GitHub's OIDC identity
# provider, so CI cannot assume roles with short-lived tokens; each user is
# scoped to the single job it serves to keep a leaked key's reach small.
resource "aws_iam_user" "this" {
  name = var.name
  path = "/ci/"
}

resource "aws_iam_user_policy" "this" {
  name   = var.name
  user   = aws_iam_user.this.name
  policy = var.policy_json
}

# Rotate by replacing it: terraform apply -replace=<address of this key>,
# then update the GitHub secrets from the new outputs.
resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}
