# Summary for the CTO

**Where we are.** Your API now has a dev and a prod environment on Azure, defined entirely in
Terraform and delivered through GitHub. Each environment has its own container registry, a managed
container runtime (Azure Container Apps), a Key Vault for secrets and central logging. Dev scales to
zero when idle to keep cost low; prod keeps at least one instance warm.

**How changes reach production.** Every infrastructure change starts as a pull request. Before
anyone merges, the pull request shows exactly what would change in dev and in prod. After merge, dev
is updated automatically. Prod is only changed after a named reviewer approves in GitHub, and what
gets applied is precisely what they approved. Every approval is recorded.

**Security.** There are no passwords, keys or long-lived tokens in the code or the pipeline:
GitHub proves its identity to Azure on each run. The pipeline that changes dev can't touch prod,
and code proposed in a pull request can only read, never change, your environments. Application
secrets live in Key Vault and are never stored in Terraform.

**Growing.** A new service is a few lines of configuration; a new environment is one entry plus a
short admin step. Dev and prod are built from the same code, so they can't drift apart in structure.

**AI.** The team uses AI assistants under shared, written rules: assistants may draft and check
changes but are technically blocked from applying them, handling secrets or bypassing review.
Everything still goes through the same pull request and approval as human work.

**Next 4–6 weeks** (two engineers, see work plan): private networking for the registry and vault,
monitoring and alerts, the application's own build-and-deploy pipeline, automated security checks
on every pull request, and cost budgets. After that we recommend a short production-readiness
review together with your team.
