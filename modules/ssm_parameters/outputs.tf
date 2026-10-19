output "resource_arns" {
  description = "ARNs covering the path itself (what GetParametersByPath is authorised against) and every parameter under it."
  value = [
    "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${var.path}",
    "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${var.path}/*",
  ]
}
