output "region" {
  description = "AWS region everything runs in."
  value       = local.region
}

output "domain_name" {
  description = "Root domain."
  value       = var.domain_name
}

output "zone_id" {
  description = "Hosted zone of the root domain."
  value       = module.dns_zone.zone_id
}

output "name_servers" {
  description = "Set these as the domain's nameservers at the registrar, once."
  value       = module.dns_zone.name_servers
}

output "vm_instance_id" {
  description = "Value for the backend repository's GitHub environment variable VM_INSTANCE_ID."
  value       = module.vm.instance_id
}

output "vm_instance_arn" {
  description = "ARN of the VM."
  value       = module.vm.instance_arn
}

output "vm_public_ip" {
  description = "Elastic IP of the VM; also the address to allow-list in MongoDB Atlas."
  value       = module.vm.public_ip
}

output "vm_role_name" {
  description = "Instance role each environment attaches its policy to."
  value       = module.vm.role_name
}

output "database_address" {
  description = "Hostname of the Postgres instance."
  value       = module.postgres.address
}

output "database_port" {
  description = "Port of the Postgres instance."
  value       = module.postgres.port
}

output "ecr_registry" {
  description = "Registry host of the service images."
  value       = module.ecr.registry
}

output "ecr_repository_arns" {
  description = "Service image repositories by name."
  value       = module.ecr.repository_arns
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = module.github_oidc.arn
}

output "ecr_push_role_arn" {
  description = "Value for the backend repository's variable AWS_ECR_PUSH_ROLE_ARN."
  value       = module.ecr_push_role.arn
}
