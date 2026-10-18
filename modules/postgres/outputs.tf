output "address" {
  description = "Hostname of the instance."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port of the instance."
  value       = aws_db_instance.this.port
}

output "master_username" {
  description = "Administrative user."
  value       = aws_db_instance.this.username
}

output "master_password" {
  description = "Administrative user's password."
  value       = random_password.master.result
  sensitive   = true
}
