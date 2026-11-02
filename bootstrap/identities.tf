# Two identities per environment, both federated with GitHub OIDC (no secrets):
#   plan  - GitHub environment plan-<env>, usable from any branch/PR, read-only
#   apply - GitHub environment <env>, main branch only (+ reviewers), can change the env RG

locals {
  identities = merge([
    for env in keys(var.environments) : {
      "${env}-plan"  = { env = env, kind = "plan", github_environment = "plan-${env}" }
      "${env}-apply" = { env = env, kind = "apply", github_environment = env }
    }
  ]...)
}

data "azuread_client_config" "current" {}

resource "azuread_application" "ci" {
  for_each     = local.identities
  display_name = "gh-${var.github_repository}-${each.key}"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "ci" {
  for_each  = local.identities
  client_id = azuread_application.ci[each.key].client_id
  owners    = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_federated_identity_credential" "ci" {
  for_each       = local.identities
  application_id = azuread_application.ci[each.key].id
  display_name   = "github-${each.value.github_environment}"
  issuer         = "https://token.actions.githubusercontent.com"
  audiences      = ["api://AzureADTokenExchange"]
  subject        = "${var.github_oidc_subject_prefix}:environment:${each.value.github_environment}"
}

# Read-only role for PR plans. Kept as a custom role (instead of built-in Reader) so extra
# read actions can be added if the provider ever needs them: add only what a failing plan proves.
resource "azurerm_role_definition" "plan" {
  name        = "Terraform Plan (${var.project})"
  scope       = "/subscriptions/${var.subscription_id}"
  description = "Read-only access needed for terraform plan of the ${var.project} stack"

  permissions {
    actions = ["*/read"]
  }

  assignable_scopes = [for rg in azurerm_resource_group.env : rg.id]
}

locals {
  # role = built-in role name; the plan identity's RG role is the custom one above
  role_assignments = merge(
    { for env in keys(var.environments) : "${env}-plan-rg" => { identity = "${env}-plan", scope = azurerm_resource_group.env[env].id, role = null } },
    { for env in keys(var.environments) : "${env}-plan-state" => { identity = "${env}-plan", scope = module.state.container_ids[env], role = "Storage Blob Data Reader" } },
    { for env in keys(var.environments) : "${env}-apply-rg" => { identity = "${env}-apply", scope = azurerm_resource_group.env[env].id, role = "Contributor" } },
    { for env in keys(var.environments) : "${env}-apply-rbac" => { identity = "${env}-apply", scope = azurerm_resource_group.env[env].id, role = "Role Based Access Control Administrator" } },
    { for env in keys(var.environments) : "${env}-apply-state" => { identity = "${env}-apply", scope = module.state.container_ids[env], role = "Storage Blob Data Contributor" } },
  )
}

resource "azurerm_role_assignment" "ci" {
  for_each             = local.role_assignments
  scope                = each.value.scope
  role_definition_name = each.value.role
  role_definition_id   = each.value.role == null ? azurerm_role_definition.plan.role_definition_resource_id : null
  principal_id         = azuread_service_principal.ci[each.value.identity].object_id
}

output "ci_identities" {
  value = { for k, app in azuread_application.ci : k => app.client_id }
}
