data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "motifpath-terraform-state"
    key    = "shared/terraform.tfstate"
    region = "us-east-2"
  }
}

locals {
  shared = data.terraform_remote_state.shared.outputs
}

# The production Clerk instance serves sign-in from these hostnames and signs
# its email with these DKIM keys; Clerk verifies each target exactly.
module "clerk_records" {
  source = "../../modules/dns_records"

  zone_id = local.shared.zone_id
  records = {
    accounts = { name = "accounts.${local.shared.domain_name}", type = "CNAME", values = ["accounts.clerk.services"] }
    frontend = { name = "clerk.${local.shared.domain_name}", type = "CNAME", values = ["frontend-api.clerk.services"] }
    dkim1    = { name = "clk._domainkey.${local.shared.domain_name}", type = "CNAME", values = ["dkim1.7tcy7qv1sd3l.clerk.services"] }
    dkim2    = { name = "clk2._domainkey.${local.shared.domain_name}", type = "CNAME", values = ["dkim2.7tcy7qv1sd3l.clerk.services"] }
    mail     = { name = "clkmail.${local.shared.domain_name}", type = "CNAME", values = ["mail.7tcy7qv1sd3l.clerk.services"] }
  }
}

module "environment" {
  source = "../../modules/environment"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  environment         = "production"
  domain_name         = local.shared.domain_name
  zone_id             = local.shared.zone_id
  vm_public_ip        = local.shared.vm_public_ip
  vm_instance_arn     = local.shared.vm_instance_arn
  instance_role_name  = local.shared.vm_role_name
  ecr_registry        = local.shared.ecr_registry
  ecr_repository_arns = local.shared.ecr_repository_arns
  database_address    = local.shared.database_address
  database_port       = local.shared.database_port
}
