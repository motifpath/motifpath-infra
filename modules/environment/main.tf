# Everything one hosted environment owns on top of the shared VM and
# database: its static hosting, API hostnames, secrets, logs, and the
# permissions scoped to them. Staging and production each call this once.

locals {
  name    = "motifpath-${var.environment}"
  db_name = "motifpath_${var.environment}"
  # Production sits at the zone's root names, staging one label down.
  suffix = var.environment == "production" ? var.domain_name : "staging.${var.domain_name}"
  hosts = {
    app    = var.environment == "production" ? "app.${var.domain_name}" : local.suffix
    api    = "api.${local.suffix}"
    events = "events.${local.suffix}"
    media  = "media.${local.suffix}"
  }
  log_group = "/motifpath/${var.environment}"
}

resource "random_password" "database" {
  length  = 32
  special = false
}

module "spa" {
  source = "../cdn_bucket"

  bucket_name     = "${local.name}-web"
  domain_name     = local.hosts.app
  zone_id         = var.zone_id
  single_page_app = true
}

module "media" {
  source = "../cdn_bucket"

  bucket_name            = "${local.name}-content-media"
  domain_name            = local.hosts.media
  zone_id                = var.zone_id
  upload_allowed_origins = ["https://${local.hosts.app}"]
}

module "api_records" {
  source = "../dns_records"

  zone_id = var.zone_id
  records = {
    api    = { name = local.hosts.api, type = "A", values = [var.vm_public_ip] }
    events = { name = local.hosts.events, type = "A", values = [var.vm_public_ip] }
  }
}

module "logs" {
  source = "../log_groups"

  names = [local.log_group]
}

# Rendered into the environment's secrets file on every deploy.
module "parameters" {
  source = "../ssm_parameters"

  path = "/motifpath/${var.environment}"
  string_parameters = {
    ECR_REGISTRY    = var.ecr_registry
    MEDIA_S3_BUCKET = module.media.bucket_name
  }
  secure_parameters = {
    DATABASE_URL = "postgres://${local.db_name}:${random_password.database.result}@${var.database_address}:${var.database_port}/${local.db_name}?sslmode=require"
  }
  manual_parameters = ["CLERK_SECRET_KEY", "MONGO_URI"]
}

# What the VM may touch on this environment's behalf.
module "instance_access" {
  source = "../iam_role_policy"

  name      = local.name
  role_name = var.instance_role_name
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadSecrets"
        Effect   = "Allow"
        Action   = ["ssm:GetParametersByPath", "ssm:GetParameters", "ssm:GetParameter"]
        Resource = module.parameters.resource_arns
      },
      {
        Sid      = "MediaObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${module.media.bucket_arn}/*"
      },
      {
        Sid      = "MediaBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = module.media.bucket_arn
      },
      {
        Sid      = "ShipLogs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${module.logs.arns[local.log_group]}:*"
      },
    ]
  })
}

# motifpath-core's deploy workflow, from its GitHub environment of the same
# name: run the deploy script on the VM and check images exist.
module "core_deploy_role" {
  source = "../github_role"

  name              = "${local.name}-core-deploy"
  oidc_provider_arn = var.github_oidc_provider_arn
  subjects          = ["repo:${var.core_repository}:environment:${var.environment}"]
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RunDeployScript"
        Effect = "Allow"
        Action = "ssm:SendCommand"
        Resource = [
          var.vm_instance_arn,
          "arn:aws:ssm:${var.region}::document/AWS-RunShellScript",
        ]
      },
      {
        Sid      = "ReadDeployResult"
        Effect   = "Allow"
        Action   = ["ssm:GetCommandInvocation", "ssm:ListCommandInvocations"]
        Resource = "*"
      },
      {
        Sid      = "CheckImages"
        Effect   = "Allow"
        Action   = ["ecr:DescribeImages"]
        Resource = values(var.ecr_repository_arns)
      },
    ]
  })
}

# motifpath-web's deploy workflow: publish the built SPA and invalidate the
# cache in front of it.
module "web_deploy_role" {
  source = "../github_role"

  name              = "${local.name}-web-deploy"
  oidc_provider_arn = var.github_oidc_provider_arn
  subjects          = ["repo:${var.web_repository}:environment:${var.environment}"]
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SyncObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${module.spa.bucket_arn}/*"
      },
      {
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = module.spa.bucket_arn
      },
      {
        Sid      = "Invalidate"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
        Resource = module.spa.distribution_arn
      },
    ]
  })
}
