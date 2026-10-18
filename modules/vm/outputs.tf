output "instance_id" {
  description = "ID of the instance, the target of deploy commands."
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the instance."
  value       = aws_instance.this.arn
}

output "public_ip" {
  description = "Elastic IP every API hostname points at."
  value       = aws_eip.this.public_ip
}

output "role_name" {
  description = "Name of the instance role; each environment attaches its own policy to it."
  value       = aws_iam_role.this.name
}

output "security_group_id" {
  description = "Security group of the instance, for granting it access to other resources."
  value       = aws_security_group.this.id
}
