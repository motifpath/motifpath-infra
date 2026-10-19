output "arns" {
  description = "Log group ARNs by name."
  value       = { for name, group in aws_cloudwatch_log_group.this : name => group.arn }
}
