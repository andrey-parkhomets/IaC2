# Work plan to production-ready

Two Middle engineers (**A**: platform/networking, **B**: delivery/observability), about 4–6 weeks.
Each task is a PR (or a few) through the normal pipeline. Estimates in engineer-days.

## Phase 1 – Safety nets (week 1)

| # | Task | Owner | Est. | Done when |
|---|---|---|---|---|
| 1 | Security scanning in CI: checkov/trivy on Terraform, results as PR annotations, fail on high | B | 1 | PRs show findings; baseline exceptions documented |
| 2 | tflint in CI (same config as pre-commit) | B | 0.5 | Lint job required on `main` |
| 3 | Cost: Azure budgets + alerts per environment RG, tags enforced by Azure Policy | A | 1 | Budget alert reaches the team channel |
| 4 | Scheduled drift detection: nightly plan of `main` for every env, issue/alert on changes | B | 1 | Manual portal change is reported next morning |
| 5 | Second reviewer: `prevent_self_review = true` on prod, 1 approval on `main`, CODEOWNERS teams | A | 0.5 | Author can't approve own prod apply |

## Phase 2 – Network and data protection (weeks 2–3)

| # | Task | Owner | Est. | Done when |
|---|---|---|---|---|
| 6 | VNet per environment; Container Apps environment with VNet integration | A | 2 | Apps run in the VNet; plan is replace-free for prod or migration documented |
| 7 | Private endpoints + private DNS for ACR (Premium in prod) and Key Vault; disable public access | A | 2 | Vault/registry unreachable from internet; apps still pull and read secrets |
| 8 | State account: private endpoint or IP allow-list for GitHub runners (or self-hosted runners in the VNet) | A | 1.5 | State not publicly reachable; CI still works |
| 9 | ~~Restrict the apply identity's RBAC Administrator role with a condition~~ **done** (`bootstrap/identities.tf`); remaining: a main-only check that a forbidden role grant is denied | A | 0.25 | Apply identity provably can't grant Owner/Contributor |

## Phase 3 – Application delivery and operations (weeks 2–4, parallel)

| # | Task | Owner | Est. | Done when |
|---|---|---|---|---|
| 10 | App pipeline (in the API repo): build, scan, push to ACR via OIDC identity with AcrPush, deploy new revision to dev, promote the same image digest to prod with approval | B | 3 | Commit to API main reaches prod after approval, no infra PR needed |
| 11 | Health probes, revision-based blue/green with traffic split for prod | B | 1.5 | Failed revision gets no traffic; rollback is one command |
| 12 | Monitoring: Application Insights, availability test, alerts on 5xx, latency, restarts; action group | B | 2 | Alert fires in a drill |
| 13 | Custom domain + managed certificate for prod; optional Front Door/WAF decision | A | 1.5 | API served on client domain over TLS |
| 13b | *Optional, on trigger (README decision 7):* API Management in front of the services, starting from the Apim-Samples Front Door/Private Link pattern | A | 3–5 | Consumers go through APIM; services have internal ingress only |
| 14 | Secrets runbook: how to add/rotate a secret in Key Vault, app reference via `key_vault_secrets` | A | 0.5 | Runbook tested on dev |

## Phase 4 – Hardening and handover (weeks 5–6)

| # | Task | Owner | Est. | Done when |
|---|---|---|---|---|
| 15 | Backup/DR: document RPO/RTO, state recovery drill (versioning/soft delete), Key Vault recovery | A | 1 | Drill done, runbook in repo |
| 16 | Upgrade path: azurerm 5.x evaluation, Terraform version policy | B | 1 | Upgrade PR or documented decision |
| 17 | Separate prod subscription (optional, recommended for blast radius) using the per-env subscription variable | A | 1.5 | Prod in its own subscription, same pipeline |
| 18 | Production-readiness review with the client; README/runbooks updated | both | 1 | Sign-off |

## Risks to watch

- Moving Container Apps into a VNet replaces the environment: do it before prod carries traffic.
- Private networking breaks GitHub-hosted runners' access to state/vault; decide on runners in task 8 early.
- Purge protection in prod is irreversible; vault names can't be reused for 90 days.
