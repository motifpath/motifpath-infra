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

output "core_deploy_access_key_id" {
  description = "Key ID motifpath-core's deploy workflow signs in with."
  value       = module.core_deploy_user.access_key_id
}

output "core_deploy_secret_access_key" {
  description = "Secret of that key."
  value       = module.core_deploy_user.secret_access_key
  sensitive   = true
}

output "web_deploy_access_key_id" {
  description = "Key ID motifpath-web's deploy workflow signs in with."
  value       = module.web_deploy_user.access_key_id
}

output "web_deploy_secret_access_key" {
  description = "Secret of that key."
  value       = module.web_deploy_user.secret_access_key
  sensitive   = true
}

output "deploy_document_name" {
  description = "SSM document motifpath-core's deploy workflow sends."
  value       = module.deploy_document.name
}
