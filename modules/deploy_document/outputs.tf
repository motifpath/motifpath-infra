output "name" {
  description = "Name to pass as --document-name."
  value       = aws_ssm_document.this.name
}

output "arn" {
  description = "ARN of the document, for ssm:SendCommand permissions."
  value       = aws_ssm_document.this.arn
}
