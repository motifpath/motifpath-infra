output "access_key_id" {
  description = "Access key ID."
  value       = aws_iam_access_key.this.id
}

output "secret_access_key" {
  description = "Secret access key."
  value       = aws_iam_access_key.this.secret
  sensitive   = true
}
