resource "aws_iam_role_policy" "this" {
  name   = var.name
  role   = var.role_name
  policy = var.policy_json
}
