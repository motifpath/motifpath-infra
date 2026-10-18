output "access_key_id" {
  description = "Value for the GitHub secret AWS_ACCESS_KEY_ID."
  value       = aws_iam_access_key.this.id
}

output "secret_access_key" {
  description = "Value for the GitHub secret AWS_SECRET_ACCESS_KEY."
  value       = aws_iam_access_key.this.secret
  sensitive   = true
}
