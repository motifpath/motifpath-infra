# motifpath-infra

Terraform infrastructure for MotifPath. All cloud resources are managed here.

## Infrastructure

MotifPath is hosted in one AWS account in `us-east-2`, the Region the AWS project is pinned
to (regional resources cannot be created anywhere else). Only the CloudFront certificates are
issued in `us-east-1`, the one Region CloudFront accepts them from. A single arm64 EC2 VM runs both
**staging** and **production** as separate Docker Compose projects. The Compose files and the
deploy script are in [motifpath-core `deploy/`](../motifpath-core/deploy/README.md). This
repository creates everything around the VM.

| Resource | Where | Purpose |
|---|---|---|
| EC2 `t4g.medium` + Elastic IP | `shared` | Runs both environments' services, Redpanda, and the Caddy edge proxy |
| RDS Postgres 16 `db.t4g.micro` | `shared` | One instance; databases `motifpath_staging` and `motifpath_production` |
| Route 53 zone `motifpath.com` | `shared` | Every DNS record, including apex/www and `_dmarc` |
| ECR | `shared` | `motifpath/{core-domain,event-ingestion,aggregation-worker}`, immutable tags |
| ECR push IAM user | `shared` | Image builds from motifpath-core's `stage`/`main` (key in its GitHub environment `images`) |
| AWS Budget | `shared` | Monthly spend alerts |
| S3 + CloudFront (SPA, media) | per env | `app.`/`staging.` and `media.`/`media.staging.` |
| Mail DNS (GoDaddy business email) | `shared` | Apex SPF/verification TXT, MX, DKIM, autodiscover; DMARC via `dmarc_record` |
| Clerk DNS | `production` | Frontend API, accounts, mail and DKIM CNAMEs for the production Clerk instance |
| API DNS records | per env | `api.`, `events.` (and `.staging.`) → the VM |
| SSM Parameter Store | per env | `/motifpath/<env>/…`, rendered into the env's secrets file at deploy |
| Media IAM user | per env | core-domain's credentials, limited to that env's media bucket |
| Deploy document | per env | The only command a deploy user can send to the VM; deploys a SHA from the env's release branches |
| CloudWatch log groups | per env | `/motifpath/<env>` and `/motifpath/edge` |
| Deploy IAM users | per env | motifpath-core (its deploy document; production also tags images it deploys) and motifpath-web (S3 sync + invalidation) |

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

7. **GitHub (motifpath-core).** CI signs in with IAM-user keys kept as GitHub *environment*
   secrets (this project does not allow GitHub's OIDC provider). Create three environments, each
   limited under **Deployment branches** to the branches shown:

   | Environment | Branches | Secrets `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` from | Variable |
   |---|---|---|---|
   | `images` | `stage`, `main` | `shared`: `ecr_push_access_key_id` / `ecr_push_secret_access_key` | — |
   | `staging` | `stage`, `main` | `staging`: `core_deploy_access_key_id` / `core_deploy_secret_access_key` | `VM_INSTANCE_ID` |
   | `production` | `main` | `production`: `core_deploy_access_key_id` / `core_deploy_secret_access_key` | `VM_INSTANCE_ID` |

   Read a secret with `terraform output -raw <name>`; `VM_INSTANCE_ID` is `shared`'s
   `vm_instance_id`. Add required reviewers to `production`. motifpath-web gets the
   `web_deploy_*` keys the same way, in its own `staging` and `production` environments.

   **Rotating a key:** `terraform apply -replace='module.<path>.aws_iam_access_key.this'`, then
   update the secrets.

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
3. Open a PR — CI runs format check and validation automatically (and a plan, once a read-only
   key is in the GitHub environment `plan` and `TF_PLAN_ENABLED` is `true`)
4. Get PR approval
5. Apply `shared` if it changed, then staging: `cd environments/staging && terraform apply`
6. Verify staging is healthy
7. Apply to production: `cd environments/production && terraform apply`

`shared` changes reach both environments at once; review those plans with that in mind.

## Isolation on the shared VM

- Containers cannot reach the instance role: the metadata hop limit is 1, so only the host can
  use it (to render secrets, pull images and ship logs). core-domain uses its own environment's
  media IAM user instead.
- Deploy users cannot run arbitrary commands. Each environment has one SSM document. It takes only
  an image SHA, refuses a SHA that is not on that environment's branches (`main` for production;
  `stage` or `main` for staging), and fetches `deploy/` from that commit on GitHub. Code reaches the
  host only by being merged to those branches.
- Production deploys tag their images `production-<sha>`. ECR expires those images only among
  themselves, so staging builds never push out an image production may need to roll back to.

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
