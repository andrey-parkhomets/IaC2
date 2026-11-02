# PR review

The pull request to review was referenced as "[link to the repository]" in the assignment and has
not been shared yet. Requested from 2ops; the review will be added here and as comments on the PR.

## How I will review it

Comments are tagged so the author knows what blocks a merge:

- **blocker** – security, data loss, prod impact, broken pipeline
- **should** – maintainability, conventions, missing docs/tests
- **nit** – style; optional
- **praise** – what's good and should be repeated

Checklist I go through, in this order:

1. **Plan first.** What does the plan say for dev and prod? Any destroy/replace, and is it intended?
2. **Credentials and secrets.** Secrets in code/tfvars/outputs, long-lived credentials, outputs not
   marked `sensitive`, secrets leaking into state where avoidable.
3. **Blast radius and privilege.** New roles/scopes for identities, public exposure (ingress,
   network access), changes to protections, CODEOWNERS or workflows.
4. **Environment parity.** Is the change data in tfvars or structure in the stack? Prod-only
   hacks, hardcoded names/IDs/regions.
5. **Terraform quality.** Module boundaries, variable types/validation/descriptions, `for_each`
   over `count` for stable addresses, `moved` blocks for refactors, pinned versions, lock file.
6. **Pipeline.** Pinned actions, permissions minimal, no `pull_request_target` with checkout of PR
   code, approvals not weakened.
7. **Docs and the PR itself.** Description, template, AI-assistance section, README decisions.
