# Day one for the two engineers

## Access (least privilege, no standing prod rights)

| Who | GitHub | Azure |
|---|---|---|
| Middle engineers | Write on the repo; members of the CODEOWNERS team for `infra/`, `modules/`, `envs/dev/` | Reader on the subscription, Contributor on `rg-saasapi-dev` for debugging, no prod write |
| Tech lead | Admin; required reviewer of the `prod` environment | Owner (bootstrap only, via PIM when available) |

Prod changes go only through the pipeline. Once there are two engineers, flip
`prevent_self_review = true` on `prod` and require one approving review on `main`.

## Working agreement

- Trunk-based: short-lived branches, PR to `main`, squash merge, conventional commits.
- A PR is reviewed on its **plan comments**, not only the diff. Destroy/replace must be explained.
- One change per PR; prod sizing changes in separate PRs.
- Definition of done: plans clean in both environments, docs/variables updated, applied to dev.
- Weekly 30-min review of drift (re-run plan on `main`), Dependabot PRs and costs.

## Local setup

```sh
brew install terraform tflint pre-commit gitleaks azure-cli gh
pre-commit install
az login && gh auth login
cd infra && terraform init -backend=false && terraform validate
```

Engineers don't need local state access for daily work; CI plans every PR.

## AI assistants: conventions

The rules are in [CLAUDE.md](../CLAUDE.md) (read by Claude Code; `AGENTS.md` points other tools to
it). The short version:

1. **Allowed:** drafting modules and docs, explaining plans and errors, reviewing PRs, writing
   tests and checks.
2. **Enforced, not just written:** `.claude/settings.json` denies `terraform apply/destroy/state`,
   merges, GitHub secret/variable changes and reading state or plan files; pushes, PR comments,
   `az` and `terraform plan` require confirmation. Even if a rule is bypassed, assistants run with
   the engineer's own rights, which have no prod write.
3. **No secrets or client data in prompts.** Use business/enterprise AI plans with no training on
   our data; never paste state, plans with sensitive values, or customer data.
4. **Verify everything.** Assistants invent versions and arguments. Every version comes from a
   registry or a release page, every change passes `fmt`/`validate`/plan, and the PR template asks
   what was AI-assisted and how it was checked.
5. **Same review bar.** AI-written code gets the same review as human code; the author owns it.
6. **Share what works.** Useful prompts and corrections go into `CLAUDE.md` via PR, so all
   assistants and engineers improve together.
