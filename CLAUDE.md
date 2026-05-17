# MotifPath Infra — Claude Code Instructions

## Purpose
Terraform configurations for all MotifPath cloud infrastructure.
AWS-hosted: EKS (compute), RDS Postgres (core-domain), MongoDB Atlas (event-ingestion),
ECR (container registry), GitHub Actions (CI/CD). MSK (Kafka) is deferred — do not provision yet.

## Directory Structure
```
modules/              → reusable Terraform modules (one per resource type)
environments/
  staging/            → staging environment (mirrors production at reduced scale)
  production/         → production environment
scripts/              → helper scripts for cluster and deployment operations
```

## Terraform Standards
NEVER write inline resource configurations — always extract to a module in /modules/.
ALWAYS run `terraform plan` and review the full output before `terraform apply`.
ALWAYS version-pin all providers in `required_providers` — no floating versions.
State is stored in S3 with DynamoDB locking — NEVER use local state files.

## Tagging Policy
ALWAYS tag every resource with:
```
environment = "staging" | "production"
project     = "motifpath"
managed-by  = "terraform"
```
Untagged resources will be flagged in cost reviews.

## Secrets
NEVER hardcode secrets, credentials, or connection strings in Terraform files.
ALWAYS reference secrets from AWS Secrets Manager.
NEVER commit .tfvars files containing sensitive values — these are gitignored.
Sensitive outputs MUST use `sensitive = true`.

## Environment Rules
ALWAYS test infrastructure changes in staging before applying to production.
NEVER run `terraform apply` against production without a reviewed and approved plan in the PR.
Staging and production use separate state files and separate AWS accounts.

## Key Rules
NEVER use `terraform apply -auto-approve` in any environment.
NEVER destroy resources in production without an explicit ADR documenting the decision.
ALWAYS use `for_each` over `count` for resource collections — avoids index-based state issues.
Module inputs must be documented with `description` on every variable — no undocumented variables.

## Branching
Feature branches target `dev` — NEVER open a PR directly to `main`.
Hotfix branches are the only exception: `hotfix/BUG-NNN/description` branches from `main`.
After a hotfix merges to `main`, the sync workflow opens a PR to `dev` automatically — review it promptly.
Infrastructure hotfixes still require a `terraform plan` review before applying — urgency never skips the plan step.