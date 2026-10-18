# motifpath-infra

Terraform infrastructure for MotifPath. All cloud resources are managed here.

## Infrastructure

MotifPath is hosted in one AWS account in `us-east-1`. A single arm64 EC2 VM runs both
**staging** and **production** as separate Docker Compose projects. The Compose files and the
deploy script are in [motifpath-core `deploy/`](../motifpath-core/deploy/README.md). This
repository creates everything around the VM.

| Resource | Where | Purpose |
|---|---|---|
| EC2 `t4g.medium` + Elastic IP | `shared` | Runs both environments' services, Redpanda, and the Caddy edge proxy |
| RDS Postgres 16 `db.t4g.micro` | `shared` | One instance; databases `motifpath_staging` and `motifpath_production` |
| Route 53 zone `motifpath.com` | `shared` | Every DNS record, including apex/www and `_dmarc` |
| ECR | `shared` | `motifpath/{core-domain,event-ingestion,aggregation-worker}`, immutable tags |
| GitHub OIDC provider + ECR push role | `shared` | Image builds from motifpath-core's `stage`/`main` |
| AWS Budget | `shared` | Monthly spend alerts |
| S3 + CloudFront (SPA, media) | per env | `app.`/`staging.` and `media.`/`media.staging.` |
| API DNS records | per env | `api.`, `events.` (and `.staging.`) → the VM |
| SSM Parameter Store | per env | `/motifpath/<env>/…`, rendered into the env's secrets file at deploy |
| CloudWatch log groups | per env | `/motifpath/<env>` and `/motifpath/edge` |
| Deploy roles | per env | motifpath-core (SSM Run Command) and motifpath-web (S3 sync + invalidation) |

Not managed here (yet): **MongoDB Atlas** clusters (Flex for production, M0 for staging,
allow-listed to the VM's Elastic IP) and **Clerk**. Kafka is a Redpanda container per environment
on the VM; MSK is not used.

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

Terraform selects its environment by directory, not by branch, so this repository has no
`stage` branch.

## Prerequisites

- [Terraform 1.10+](https://developer.hashicorp.com/terraform/install) (S3-native state locking)
- [AWS CLI](https://aws.amazon.com/cli/) — configured with credentials for the account
- [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) and `psql`, for `scripts/create-environment-database.sh`

## Layout

```
bootstrap/                 → state bucket (applied once, first)
modules/                   → one module per resource type; modules/environment composes them
environments/shared/       → resources both environments use
environments/staging/      → staging's own resources
environments/production/   → production's own resources
scripts/                   → operator helpers
```

Each root has its own state file. `staging` and `production` read `shared`'s outputs through
`terraform_remote_state`, so `shared` is always applied first.

## First-time setup

Nothing here exists yet. Run these once, in order.

1. **State bucket.** The bucket cannot hold its own state before it exists, so the first apply
   uses a local backend through a gitignored override file. The state is then moved into the
   bucket.

   ```bash
   cd bootstrap
   printf 'terraform {\n  backend "local" {}\n}\n' > backend_override.tf
   terraform init && terraform apply
   rm backend_override.tf
   terraform init -migrate-state      # answer yes; then delete the local terraform.tfstate*
   ```

2. **Shared.** Variables without defaults go in a gitignored `environments/shared/operator.auto.tfvars`:

   ```hcl
   budget_alert_emails = ["…"]
   dmarc_record        = "v=DMARC1; p=quarantine; rua=mailto:…"   # copy the current GoDaddy value
   ```

   ```bash
   cd environments/shared && terraform init && terraform plan && terraform apply
   terraform output name_servers
   ```

3. **Nameservers.** In GoDaddy, switch `motifpath.com`'s nameservers to the four from the
   output, once. Every record is in Route 53 from then on. The CloudFront certificates in the
   next step wait for DNS validation, so do this before applying the environments.

4. **Environments.**

   ```bash
   cd environments/staging    && terraform init && terraform plan && terraform apply
   cd environments/production && terraform init && terraform plan && terraform apply
   ```

5. **Databases.** Create each environment's database and user on the shared instance:

   ```bash
   scripts/create-environment-database.sh staging
   scripts/create-environment-database.sh production
   ```

6. **Hand-set secrets.** Terraform creates these with the value `SET_ME` and never overwrites
   them afterwards:

   ```bash
   aws ssm put-parameter --overwrite --type SecureString --name /motifpath/edge/ACME_EMAIL --value …
   for env in staging production; do
     aws ssm put-parameter --overwrite --type SecureString --name /motifpath/$env/CLERK_SECRET_KEY --value …
     aws ssm put-parameter --overwrite --type SecureString --name /motifpath/$env/MONGO_URI --value …
   done
   ```

   Create the Atlas clusters first, and allow-list `terraform -chdir=environments/shared output -raw vm_public_ip`.

7. **GitHub (motifpath-core).** Set the repository variable `AWS_ECR_PUSH_ROLE_ARN` from
   `shared`'s `ecr_push_role_arn`. Create GitHub environments `staging` and `production`, each
   with `AWS_DEPLOY_ROLE_ARN` (that environment's `core_deploy_role_arn`) and `VM_INSTANCE_ID`
   (`shared`'s `vm_instance_id`).

## Commands

```bash
# Format all Terraform files
terraform fmt -recursive

# Validate a root without touching state
cd environments/staging && terraform init -backend=false && terraform validate

# Plan, then apply after reviewing the full plan
cd environments/staging && terraform plan
cd environments/staging && terraform apply
```

## Workflow

1. Make infrastructure changes in a feature branch
2. Run `terraform fmt -recursive` and `terraform validate` locally
3. Open a PR — CI runs format check and validation automatically (and a plan, once
   `AWS_PLAN_ROLE_ARN` is set)
4. Get PR approval
5. Apply `shared` if it changed, then staging: `cd environments/staging && terraform apply`
6. Verify staging is healthy
7. Apply to production: `cd environments/production && terraform apply`

`shared` changes reach both environments at once; review those plans with that in mind.

## State Management

Terraform state lives in the S3 bucket `motifpath-terraform-state`, versioned, with S3-native
locking. Never use local state files.

## Secrets

Secrets are SSM Parameter Store `SecureString` values under `/motifpath/<env>/` and
`/motifpath/edge/`. Generated secrets (database passwords) are written by Terraform; secrets
from other systems (Clerk, Atlas) are set by hand. Never hardcode credentials in Terraform files,
and never commit `.tfvars` files containing sensitive values — they are gitignored.

## Related Repositories

| Repository | Purpose |
|---|---|
| [motifpath-specs](../motifpath-specs) | Platform contracts and architecture decisions |
| [motifpath-core](../motifpath-core) | Go backend services; `deploy/` runs them on the VM |
| [motifpath-web](../motifpath-web) | Vue 3 SPA, served from S3 + CloudFront |
