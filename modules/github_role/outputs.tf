output "arn" {
  description = "ARN of the role, for the workflow's role-to-assume."
  value       = aws_iam_role.this.arn
}
