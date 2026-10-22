# MotifPath Infra — Claude Code Instructions

## Purpose
Terraform configurations for all MotifPath cloud infrastructure, in one AWS account (`us-east-2`).
The account is an AWS project in the new AWS experience: an AWS-managed SCP denies regional
resources outside `us-east-2`. The only `us-east-1` resources are CloudFront's ACM certificates,
created through the `aws.us_east_1` provider alias — NEVER put anything else there.
One arm64 EC2 VM runs both staging and production as Docker Compose projects (the Compose files
and deploy script live in motifpath-core `deploy/`). Around it: one RDS Postgres instance holding
a database per environment, ECR, S3 + CloudFront for the SPA and media, Route 53, SSM Parameter
Store for secrets, and IAM users whose keys GitHub Actions uses (the project's SCP denies GitHub's
OIDC provider, so there are no OIDC roles; one narrowly scoped user per CI job). Kafka is a Redpanda container per environment on the VM
— do not provision MSK. MongoDB Atlas clusters are created by hand for now (not in Terraform).

## Directory Structure
```
bootstrap/            → the state bucket; applied once, first
modules/              → reusable Terraform modules (one per resource type);
                        modules/environment composes them into one hosted environment
environments/
  shared/             → what both environments use: network, VM, RDS, DNS zone, ECR, CI push user, budget
  staging/            → staging's own resources (reads shared's outputs via remote state)
  production/         → production's own resources
scripts/              → operator helpers (creating an environment's database, promoting an admin)
```
Apply order: `bootstrap` → `environments/shared` → `environments/staging` → `environments/production`.

## Terraform Standards
NEVER write inline resource configurations — always extract to a module in /modules/.
ALWAYS run `terraform plan` and review the full output before `terraform apply`.
ALWAYS version-pin all providers in `required_providers` — no floating versions.
State is stored in S3 with S3-native locking (`use_lockfile`, Terraform ≥ 1.10) — NEVER use local
state files. The only exception is the one-time bootstrap, whose state is migrated into the bucket.

## Tagging Policy
ALWAYS tag every resource with:
```
environment = "staging" | "production" | "shared"
project     = "motifpath"
managed-by  = "terraform"
```
Untagged resources will be flagged in cost reviews. Each root sets these through the provider's
`default_tags`; `shared` is for resources both environments use.

## Secrets
NEVER hardcode secrets, credentials, or connection strings in Terraform files.
Secrets live in SSM Parameter Store `SecureString` values under `/motifpath/<env>/` — not Secrets
Manager. Secrets Terraform must never see (Clerk keys, Atlas URIs) are `manual_parameters`:
created with a placeholder, set by hand, and ignored by Terraform afterwards.
NEVER commit .tfvars files containing sensitive values — these are gitignored.
Sensitive outputs MUST use `sensitive = true`.

## Environment Rules
ALWAYS test infrastructure changes in staging before applying to production.
NEVER run `terraform apply` against production without a reviewed and approved plan in the PR.
Staging and production use separate state files in one AWS account; they are kept apart by
state, resource names, the `environment` tag, and IAM policies scoped per environment.
They share one VM, so these hold on it:
- Containers cannot reach the instance role (IMDS hop limit 1). Only the host can, and it can
  read both environments' secrets. Services get their own narrow credentials (e.g. the
  per-environment media IAM user); NEVER raise the hop limit or grant a container the role.
- Deploy users may only send their environment's fixed deploy document, which takes an image SHA,
  checks it is on that environment's release branches, and fetches deploy files itself.
  NEVER grant a deploy user `AWS-RunShellScript` or any document that runs caller-supplied code.

## Key Rules
NEVER use `terraform apply -auto-approve` in any environment.
NEVER destroy resources in production without an explicit ADR documenting the decision.
ALWAYS use `for_each` over `count` for resource collections — avoids index-based state issues.
Module inputs must be documented with `description` on every variable — no undocumented variables.
NEVER reference an ADR, backlog item (PB-NNN), ticket, or spec file by name/number in a Terraform
comment — state the invariant, constraint, or reason in the comment's own words instead. A doc
reference goes stale the moment that document is archived or renumbered, and forces every future
reader (human or AI) into an external lookup to understand code sitting in front of them. Doc
references belong in commit messages and PR descriptions, which are allowed to age — never in
the comment itself.

## Branching
Feature branches target `dev` — NEVER open a PR directly to `main`.
Hotfix branches are the only exception: `hotfix/BUG-NNN/description` branches from `main`.
After a hotfix merges to `main`, the sync workflow opens a PR to `dev` automatically — review it promptly.
Infrastructure hotfixes still require a `terraform plan` review before applying — urgency never skips the plan step.