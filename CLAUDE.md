# motifpath-infra

Infrastructure as code for Motifpath. All cloud resources are defined here.

## Hard rules

- No secrets in code — ever. Use environment variables injected by CI or a secrets manager
- `terraform apply` on prod only happens via CI after a PR merge, never manually
- Every resource must have standard tags: `project`, `env`, `managed-by=terraform`
- Destructive changes (resource deletion, database migrations) require explicit confirmation in the PR description

## Module conventions

- Each module in `terraform/modules/` is self-contained with its own `variables.tf`, `outputs.tf`, and `README.md`
- Module inputs have descriptions and type constraints
- Sensitive outputs are marked `sensitive = true`

## CI / plan workflow

- PRs trigger `terraform plan` and post the output as a PR comment
- Merging to main triggers `terraform apply` for dev automatically
- Staging and prod require manual approval in the GitHub Actions workflow

## How to help

- Flag any resource change that could cause downtime
- Suggest tagging or naming if it deviates from convention
- Always recommend `terraform plan` output review before apply
- Never suggest bypassing the PR-to-apply workflow
