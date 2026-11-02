# Working in this repo (humans and AI assistants)

Terraform for a containerised API on Azure (dev, prod), delivered by GitHub Actions.
Read `README.md` (decisions) before proposing structural changes.

## Layout

- `infra/` – the one stack every environment uses. Environments are data only.
- `envs/<env>/terraform.tfvars` – sizing and services; `envs/<env>/backend.hcl` – generated, don't edit.
- `modules/platform` – per-environment shared pieces (Log Analytics, Container Apps env, ACR, Key Vault).
- `modules/container-service` – one service (identity, role assignments, Container App).
- `bootstrap/` – admin-only: state, resource groups, CI identities, GitHub environments.
- `.github/workflows/` – `infra.yml` (entry), `terraform-env.yml` (plan/apply one env).

## Rules

1. **Never apply.** Changes reach Azure only through a PR and the pipeline. Don't run
   `terraform apply/destroy/import/state`, `az ... create/delete/update`, or anything that
   changes GitHub settings. Plans locally are fine.
2. **No secrets anywhere** – not in code, tfvars, prompts, commit messages or PR text.
   Secret values live in Key Vault and are referenced via `key_vault_secrets`. Never read
   `*.tfstate` or plan files: they contain secrets.
3. **Add, don't fork.** New service = entry in `services` in `envs/<env>/terraform.tfvars`.
   New environment = entry in `bootstrap/terraform.tfvars` + `envs/<env>/` + one job in `infra.yml`.
   Don't copy stacks per environment.
4. **Least privilege stays.** Don't widen CI identity roles, environment protections,
   branch protection or `.claude/settings.json` without saying so explicitly in the PR.
5. **Verify before claiming.** Run `terraform fmt -recursive` and `terraform validate` (in
   `infra/` and `bootstrap/` after `init -backend=false`). Check provider/action/module
   versions against the registry or releases – don't guess them. Pin actions to commit SHAs.
6. **Small PRs**, conventional commits (`feat(infra): ...`, `fix(ci): ...`), PR template filled
   in, including the "AI assistance" section.

## Conventions

- Names: `<type>-<service>-<env>`, unique ones via `Azure/avm-utl-naming` (`name_unique`).
- Every variable has `type` and `description`; validation where input is user-facing.
- azurerm `~> 4.81`; Terraform `>= 1.9, < 2.0`; CI uses 1.15.1.
- Image tags are owned by the application pipeline (`ignore_changes` on the image).
