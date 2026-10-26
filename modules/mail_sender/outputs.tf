output "smtp_host" {
  description = "SES SMTP endpoint of the region the identity lives in."
  value       = "email-smtp.${local.region}.amazonaws.com"
}

output "smtp_username" {
  description = "SMTP user name: the sending user's access key ID."
  value       = aws_iam_access_key.this.id
}

output "smtp_password" {
  description = "SMTP password derived from the sending user's secret key for this region."
  value       = aws_iam_access_key.this.ses_smtp_password_v4
  sensitive   = true
}

output "from_address" {
  description = "Address the environment's email is sent from."
  value       = "noreply@${var.domain}"
}
