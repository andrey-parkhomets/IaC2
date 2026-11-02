subscription_id   = "16311667-b599-473f-b4c6-0152bace79a0"
location          = "polandcentral"
project           = "saasapi"
github_owner      = "andrey-parkhomets"
github_repository = "IaC2"

# gh api repos/andrey-parkhomets/IaC2/actions/oidc/customization/sub -q .sub_claim_prefix
github_oidc_subject_prefix = "TO_BE_SET_AFTER_REPO_CREATION"

environments = {
  dev  = {}
  prod = { reviewers = ["andrey-parkhomets"] }
}

admin_principal_ids = [
  "af21bc71-df86-45fa-8358-05bbea39ad48", # andrey.parkhomets
]
