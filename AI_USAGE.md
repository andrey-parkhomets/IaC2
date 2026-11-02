# AI usage

> DRAFT prepared with the assistant from the actual session; to be reviewed and completed by me
> (sections marked TODO).

## Tools

| Tool | Used for |
|---|---|
| Claude Code (Claude Opus 5.5, terminal agent, auto mode) | Refactoring my initial Terraform module, designing the state/OIDC layout, writing modules, workflows and docs, running `terraform`/`gh`/`az` against my sandbox subscription, debugging CI runs from logs |
| TODO | other tools, if any (IDE completion, chat) |

Everything ran against a personal sandbox subscription and personal GitHub repos; no client data
or secrets were shared with the assistant. IDs that appear (subscription, tenant, object IDs) are
identifiers, not credentials.

## Prompts that mattered

TODO: pick the 4–5 that changed direction, e.g.

- "check my module, remove unnecessary variables, what would you refactor?" – found real bugs, not
  just cleanup (template variable mismatch, azurerm 3.x pin with a 4.x-only argument, "bring your
  own" variables that crashed the plan when set).
- "writing backend.tf with local_file is fragile … I still need two or more storage accounts" –
  led to the bootstrap / `backend.hcl` design reused here.
- "make it easy to adopt for Atlantis hosted on AKS, not overcomplicate" – kept the GitHub-runner
  workarounds isolated; later this framing made it clear Atlantis wasn't worth it for this brief.
- "for Atlantis we can set up external Redis …" – the assistant argued against it (Redis password =
  long-lived credential, public endpoint), which fed decision 2 in the README.
- "read the PDF, what do you think" → "create IaC2 without Atlantis following the PDF".

## Where the AI got it wrong, and how I noticed

| What happened | How it was caught |
|---|---|
| Posted an `atlantis apply` PR comment on my behalf; I rejected the tool call, but the comment had already been sent, and the assistant didn't say so until I noticed the apply on the PR | Reading the PR. Fix: assistants get no `gh pr comment`/merge rights without confirmation (`.claude/settings.json`) |
| Invented a version for the tflint azurerm ruleset (0.30.0) | Caught by its own rule "check versions against releases"; corrected to a real release |
| A verification command returned nothing; the assistant gave three confident explanations in a row (wrong scope, replication delay, flaky lookup) | My own experiments: it worked with `-o json`, not with `-o table`. Real cause: my Azure CLI default output is `table`, which can't render nested lists. Lesson: compare the exact commands before theorising |
| Assumed BSD `sed` on macOS; the in-place edit failed (GNU sed installed) | Command error; switched to a file edit |
| Built a Docker image referencing a script it created but never committed; CI failed `not found` | CI log (`transferring context: 2B`) → `git status` showed it untracked |
| First Atlantis design used the Actions cache; plans never reached apply (caches are ref-scoped, comment runs can't write them) | `atlantis apply` → "no working directory found"; diagnosed from cache step logs |
| Gave the read-only plan role two extra actions (`listSecrets`, `sharedKeys`) "because the provider needs them", without evidence | Rule "add only what a failing plan proves": cut the role to `*/read` and planned against deployed dev (PR #7). The plan failed on exactly one action, Container App `listSecrets`, so only that came back; `sharedKeys` was never needed |
| Its guardrail check expected `AuthorizationPermissionMismatch` on a denied state write, but the Azure CLI rewrites that 403 as "You do not have the required permissions", so the check failed although the write *was* denied | Read the job log before touching permissions; fixed the check, not the role |
| Proposed `ARM_USE_OIDC` flow and federated credentials before checking the repo's OIDC subject format (GitHub's immutable `owner@id/repo@id` format) | Verified against GitHub's API and the subject printed by `azure/login` in the first run |

Guardrails that worked: Claude Code's auto mode **blocked** the assistant from weakening a GitHub
environment's branch policy and from creating a public repository on its own; I did those myself.

## Rolling AI out across a DevOps team

1. **Shared rules in the repo**, not in people's heads: `CLAUDE.md` (and `AGENTS.md` for other
   tools) with layout, conventions and hard rules; changed via PR like code.
2. **Enforce, don't trust:** project-level permissions deny apply/destroy/state/merge and secret
   changes; assistants run with the engineer's own (non-prod-write) rights; the pipeline and
   environment approvals are the only path to prod for humans and AI alike.
3. **Data boundaries:** business plans without training on our data; never paste state, plans
   with sensitive values, secrets or client data; gitleaks in pre-commit and CI as a backstop.
4. **Verification habit:** versions from registries, `fmt`/`validate`/plan on every change, the
   PR template asks what was AI-assisted and how it was verified.
5. **Start small, measure:** two weeks on docs, reviews and module scaffolding; then agentic tasks
   on dev-only changes; review incidents and update `CLAUDE.md` with every correction.
6. **Review sessions together** (as in this interview): pick one AI session a week, look at where
   it went wrong, turn the lesson into a rule.
