output "hosts" {
  description = "Hostnames this environment serves."
  value       = module.environment.hosts
}

output "database_name" {
  description = "Database and user name to create on the shared Postgres instance."
  value       = module.environment.database_name
}

output "database_password" {
  description = "Password for that user; also embedded in the DATABASE_URL parameter."
  value       = module.environment.database_password
  sensitive   = true
}

output "spa_bucket_name" {
  description = "Bucket the SPA build is synced into."
  value       = module.environment.spa_bucket_name
}

output "spa_distribution_id" {
  description = "Distribution to invalidate after an SPA deploy."
  value       = module.environment.spa_distribution_id
}

output "core_deploy_role_arn" {
  description = "Value for motifpath-core's GitHub environment variable AWS_DEPLOY_ROLE_ARN."
  value       = module.environment.core_deploy_role_arn
}

output "web_deploy_role_arn" {
  description = "Role motifpath-web's deploy workflow assumes."
  value       = module.environment.web_deploy_role_arn
}

output "deploy_document_name" {
  description = "SSM document motifpath-core's deploy workflow sends to the VM."
  value       = module.environment.deploy_document_name
}
