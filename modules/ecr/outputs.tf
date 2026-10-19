output "repository_arns" {
  description = "Repository ARNs by name."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.arn }
}

output "registry" {
  description = "Registry host the repositories live under."
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.region}.amazonaws.com"
}
