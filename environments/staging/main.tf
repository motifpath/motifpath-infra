data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "motifpath-terraform-state"
    key    = "shared/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  shared = data.terraform_remote_state.shared.outputs
}

module "environment" {
  source = "../../modules/environment"

  environment              = "staging"
  region                   = local.shared.region
  domain_name              = local.shared.domain_name
  zone_id                  = local.shared.zone_id
  vm_public_ip             = local.shared.vm_public_ip
  vm_instance_arn          = local.shared.vm_instance_arn
  instance_role_name       = local.shared.vm_role_name
  ecr_registry             = local.shared.ecr_registry
  ecr_repository_arns      = local.shared.ecr_repository_arns
  github_oidc_provider_arn = local.shared.github_oidc_provider_arn
  database_address         = local.shared.database_address
  database_port            = local.shared.database_port
}
