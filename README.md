# motifpath-infra

Terraform configurations for all MotifPath cloud infrastructure, hosted on AWS.

| Resource | Service |
|----------|---------|
| Compute | EKS |
| Relational DB | RDS PostgreSQL (core-domain) |
| Document DB | MongoDB Atlas (event-ingestion) |
| Container Registry | ECR |
| CI/CD | GitHub Actions |

> **MSK (Kafka) is deferred — do not provision yet.**

## Prerequisites

- Terraform >= 1.6
- AWS CLI authenticated to the target account (`staging` or `production`)
- Access to S3 state bucket and DynamoDB lock table

## Directory Structure

```
modules/              reusable Terraform modules (one per resource type)
environments/
  staging/            staging environment (mirrors production at reduced scale)
  production/         production environment
scripts/              helper scripts for cluster and deployment operations
```

## Usage

```bash
cd environments/staging
terraform init
terraform plan        # always review the full output
terraform apply       # only after reviewing plan
```

**Never** run `terraform apply` against `production` without a reviewed and approved plan in a merged PR.

## Environments

| Environment | AWS Account | State Backend |
|-------------|-------------|---------------|
| staging | separate account | S3 + DynamoDB locking |
| production | separate account | S3 + DynamoDB locking |

Changes must be tested in **staging** before applying to **production**.

## Tagging Policy

Every resource must carry these tags:

```hcl
environment = "staging" | "production"
project     = "motifpath"
managed-by  = "terraform"
```

## Key Rules

- All resource configurations are extracted to modules in `/modules/` — no inline resources
- All provider versions are pinned in `required_providers` — no floating versions
- Secrets come from AWS Secrets Manager — never hardcoded in `.tf` files or committed `.tfvars`
- Use `for_each` over `count` for resource collections
- Every module variable has a `description` — no undocumented variables
- Destroying production resources requires an ADR documenting the decision
