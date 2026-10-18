output "hosts" {
  description = "Hostnames this environment serves."
  value       = local.hosts
}

output "database_name" {
  description = "Name of this environment's database, which is also its user's name."
  value       = local.db_name
}

output "database_password" {
  description = "Password of this environment's database user."
  value       = random_password.database.result
  sensitive   = true
}

output "spa_bucket_name" {
  description = "Bucket the SPA build is synced into."
  value       = module.spa.bucket_name
}

output "spa_distribution_id" {
  description = "Distribution to invalidate after an SPA deploy."
  value       = module.spa.distribution_id
}

output "media_bucket_name" {
  description = "Bucket core-domain stores media in."
  value       = module.media.bucket_name
}

output "core_deploy_role_arn" {
  description = "Value for the backend repository's GitHub environment variable AWS_DEPLOY_ROLE_ARN."
  value       = module.core_deploy_role.arn
}

output "web_deploy_role_arn" {
  description = "Role the SPA repository's deploy workflow assumes."
  value       = module.web_deploy_role.arn
}
