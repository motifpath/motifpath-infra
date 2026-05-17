# motifpath-infra

Terraform infrastructure for MotifPath. All cloud resources are managed here.

## Infrastructure

| Resource | Provider | Purpose |
|---|---|---|
| EKS | AWS | Kubernetes cluster (compute) |
| RDS PostgreSQL | AWS | core-domain service database |
| MongoDB Atlas | Atlas | event-ingestion service database |
| ECR | AWS | Container image registry |
| Secrets Manager | AWS | Credentials and connection strings |

> **Deferred:** MSK (Kafka) — not provisioned at MVP.

## Onboarding

First-time machine setup is handled from `motifpath-specs` — see its
[README](../motifpath-specs/README.md#onboarding) for the full setup steps
(global CLAUDE.md + Claude skill installation).

## Branching Model

```
main  (protected — production releases only)
dev   (protected — integration branch, target for all feature PRs)
```

Branch naming — task code is mandatory:

```
infra/MTP-001/short-description   ← branches from dev
hotfix/BUG-099/short-description  ← branches from main (critical production fixes only)
```

After any merge to `main`, the `sync-main-to-dev` workflow opens a PR
from `main` to `dev` automatically. Review and merge it promptly.

## Prerequisites

- [Terraform 1.7+](https://developer.hashicorp.com/terraform/install)
- [AWS CLI](https://aws.amazon.com/cli/) — configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Environments

```
environments/
  staging/      → mirrors production at reduced scale
  production/   → production environment
```

Always apply to staging first. Never apply to production without
a reviewed and approved plan in a PR.

## Commands

```bash
# Format all Terraform files
terraform fmt -recursive

# Validate staging configuration
cd environments/staging && terraform init && terraform validate

# Plan staging changes (always before apply)
cd environments/staging && terraform plan

# Apply staging changes
cd environments/staging && terraform apply

# Validate production configuration
cd environments/production && terraform init && terraform validate

# Plan production changes (requires PR approval before applying)
cd environments/production && terraform plan
```

## Workflow

1. Make infrastructure changes in a feature branch
2. Run `terraform fmt -recursive` and `terraform validate` locally
3. Open a PR — CI runs format check and validation automatically
4. Get PR approval
5. Apply to staging: `cd environments/staging && terraform apply`
6. Verify staging is healthy
7. Apply to production: `cd environments/production && terraform apply`

## State Management

Terraform state lives in S3 with DynamoDB locking.
Never use local state files.
Staging and production use separate state files and separate AWS accounts.

## Secrets

All secrets are stored in AWS Secrets Manager.
Never hardcode credentials in Terraform files.
Never commit `.tfvars` files containing sensitive values — they are gitignored.

## Related Repositories

| Repository | Purpose |
|---|---|
| [motifpath-specs](../motifpath-specs) | Platform contracts and architecture decisions |
| [motifpath-core](../motifpath-core) | Go backend services deployed to EKS |
| [motifpath-web](../motifpath-web) | Vue 3 frontend deployed to EKS |