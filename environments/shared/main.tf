# Resources both environments use: the network, the VM they run on, the
# Postgres instance holding their databases, the DNS zone, the image
# registry, the edge proxy's secrets and logs, and the GitHub identity.

locals {
  name   = "motifpath"
  region = "us-east-2"
  # The first zone hosts the VM and the database.
  availability_zones = ["us-east-2a", "us-east-2b"]
}

module "network" {
  source = "../../modules/network"

  name               = local.name
  availability_zones = local.availability_zones
}

module "vm" {
  source = "../../modules/vm"

  name      = local.name
  vpc_id    = module.network.vpc_id
  subnet_id = module.network.public_subnet_id
}

module "postgres" {
  source = "../../modules/postgres"

  name                       = local.name
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.private_subnet_ids
  allowed_security_group_ids = { vm = module.vm.security_group_id }
  availability_zone          = local.availability_zones[0]
}

module "dns_zone" {
  source = "../../modules/dns_zone"

  domain_name = var.domain_name
}

module "root_records" {
  source = "../../modules/dns_records"

  zone_id = module.dns_zone.zone_id
  records = {
    # Nothing is published at the apex; the edge proxy redirects it and www
    # to the app.
    apex  = { name = var.domain_name, type = "A", values = [module.vm.public_ip] }
    www   = { name = "www.${var.domain_name}", type = "A", values = [module.vm.public_ip] }
    dmarc = { name = "_dmarc.${var.domain_name}", type = "TXT", values = [var.dmarc_record] }
  }
}

module "ecr" {
  source = "../../modules/ecr"

  repository_names = [
    "motifpath/core-domain",
    "motifpath/event-ingestion",
    "motifpath/aggregation-worker",
  ]
}

module "edge_logs" {
  source = "../../modules/log_groups"

  names = ["/motifpath/edge"]
}

module "edge_parameters" {
  source = "../../modules/ssm_parameters"

  path              = "/motifpath/edge"
  manual_parameters = ["ACME_EMAIL"]
}

# Kept where an operator can read it to create each environment's database;
# the VM cannot.
module "admin_parameters" {
  source = "../../modules/ssm_parameters"

  path = "/motifpath/shared/postgres"
  string_parameters = {
    ADDRESS  = module.postgres.address
    USERNAME = module.postgres.master_username
  }
  secure_parameters = {
    PASSWORD = module.postgres.master_password
  }
}

# What the VM needs regardless of environment: pulling images, the edge
# proxy's secrets and logs.
module "instance_shared_access" {
  source = "../../modules/iam_role_policy"

  name      = "${local.name}-shared"
  role_name = module.vm.role_name
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid      = "PullImages"
        Effect   = "Allow"
        Action   = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer", "ecr:BatchCheckLayerAvailability"]
        Resource = values(module.ecr.repository_arns)
      },
      {
        Sid      = "EdgeSecrets"
        Effect   = "Allow"
        Action   = ["ssm:GetParametersByPath", "ssm:GetParameters", "ssm:GetParameter"]
        Resource = module.edge_parameters.resource_arns
      },
      {
        Sid      = "EdgeLogs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${module.edge_logs.arns["/motifpath/edge"]}:*"
      },
    ]
  })
}

module "github_oidc" {
  source = "../../modules/github_oidc_provider"
}

# Image builds run on pushes to the release branches only, so no other
# branch can publish an image.
module "ecr_push_role" {
  source = "../../modules/github_role"

  name              = "${local.name}-core-ecr-push"
  oidc_provider_arn = module.github_oidc.arn
  subjects = [
    "repo:${var.core_repository}:ref:refs/heads/stage",
    "repo:${var.core_repository}:ref:refs/heads/main",
  ]
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "PushImages"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ]
        Resource = values(module.ecr.repository_arns)
      },
    ]
  })
}

module "budget" {
  source = "../../modules/budget"

  name              = local.name
  monthly_limit_usd = var.monthly_budget_usd
  alert_emails      = var.budget_alert_emails
}
