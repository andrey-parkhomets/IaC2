subscription_id   = "16311667-b599-473f-b4c6-0152bace79a0"
location          = "polandcentral"
project           = "saasapi"
github_owner      = "andrey-parkhomets"
github_repository = "IaC2"

# gh api repos/andrey-parkhomets/IaC2/actions/oidc/customization/sub -q .sub_claim_prefix
github_oidc_subject_prefix = "repo:andrey-parkhomets@6885502/IaC2@1443265639"

environments = {
  dev  = {}
  prod = { reviewers = ["andrey-parkhomets"] }
}

admin_principal_ids = [
  "af21bc71-df86-45fa-8358-05bbea39ad48", # andrey.parkhomets
]

# Job names as GitHub reports them (infra.yml, guardrails.yml)
required_status_checks = [
  "validate",
  "dev / plan",
  "prod / plan",
  "plan identity is read-only (dev)",
  "plan identity is read-only (prod)",
]
