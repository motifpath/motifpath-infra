# motifpath-infra

Infrastructure as code for the Motifpath platform. Manages cloud resources, deployments, and environment configuration.

## Structure

```
terraform/
  modules/    Reusable Terraform modules
  envs/
    dev/      Development environment
    staging/  Staging environment
    prod/     Production environment
scripts/      Operational scripts
docs/         Infrastructure architecture docs
```

## Prerequisites

- Terraform >= 1.6
- Cloud provider CLI authenticated

## Usage

```bash
cd terraform/envs/dev
terraform init
terraform plan
terraform apply
```

## Conventions

- Never commit secrets; use environment variables or a secrets manager
- All changes go through PR — no direct `terraform apply` on prod
- Every module must have a `README.md` and example usage
