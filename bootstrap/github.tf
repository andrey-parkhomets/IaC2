# GitHub side of the trust: environments (where the approval gate lives), the IDs
# workflows need (not secrets), and protection of main.

data "github_user" "reviewer" {
  for_each = toset(flatten([for env in values(var.environments) : env.reviewers]))
  username = each.key
}

data "github_repository" "this" {
  name = var.github_repository
}

resource "github_repository_environment" "plan" {
  for_each    = var.environments
  repository  = var.github_repository
  environment = "plan-${each.key}"
}

resource "github_repository_environment" "apply" {
  for_each            = var.environments
  repository          = var.github_repository
  environment         = each.key
  can_admins_bypass   = false
  prevent_self_review = false # single maintainer for now; set true once the team grows

  dynamic "reviewers" {
    for_each = length(each.value.reviewers) > 0 ? [1] : []
    content {
      users = [for u in each.value.reviewers : data.github_user.reviewer[u].id]
    }
  }

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "apply_main" {
  for_each       = var.environments
  repository     = var.github_repository
  environment    = github_repository_environment.apply[each.key].environment
  branch_pattern = "main"
}

resource "github_actions_variable" "tenant" {
  repository    = var.github_repository
  variable_name = "AZURE_TENANT_ID"
  value         = data.azuread_client_config.current.tenant_id
}

resource "github_actions_environment_variable" "client_id" {
  for_each      = local.identities
  repository    = var.github_repository
  environment   = each.value.kind == "plan" ? github_repository_environment.plan[each.value.env].environment : github_repository_environment.apply[each.value.env].environment
  variable_name = "AZURE_CLIENT_ID"
  value         = azuread_application.ci[each.key].client_id
}

resource "github_actions_environment_variable" "subscription" {
  for_each      = local.identities
  repository    = var.github_repository
  environment   = github_actions_environment_variable.client_id[each.key].environment
  variable_name = "AZURE_SUBSCRIPTION_ID"
  value         = var.subscription_id
}

resource "github_branch_protection" "main" {
  repository_id = data.github_repository.this.node_id
  pattern       = "main"

  required_pull_request_reviews {
    # 0 while there is a single maintainer; prod applies still need environment approval
    required_approving_review_count = 0
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = false
  }

  required_status_checks {
    strict   = true
    contexts = var.required_status_checks
  }

  allows_force_pushes = false
  allows_deletions    = false
}
