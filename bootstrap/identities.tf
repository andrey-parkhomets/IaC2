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
    actions = [
      "*/read",
      # azurerm reads Container App secrets on refresh; proven by a failing dev plan (PR #7)
      "Microsoft.App/containerApps/listSecrets/action",
    ]
  }

  assignable_scopes = [for rg in azurerm_resource_group.env : rg.id]
}

locals {
  # The apply identity may only grant the roles the container-service module assigns to app
  # identities, so it can't escalate itself (or anyone) to Owner/Contributor.
  delegable_role_ids = [
    "7f951dda-4ed3-4680-a7ca-43fe172d538d", # AcrPull
    "4633458b-17de-408a-b874-0445c86b69e6", # Key Vault Secrets User
  ]
  rbac_condition = <<-EOT
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
     )
     OR
     (
      @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${join(", ", local.delegable_role_ids)}}
     )
    )
    AND
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
     )
     OR
     (
      @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${join(", ", local.delegable_role_ids)}}
     )
    )
  EOT

  # role = built-in role name; the plan identity's RG role is the custom one above
  role_assignments = merge(
    { for env in keys(var.environments) : "${env}-plan-rg" => { identity = "${env}-plan", scope = azurerm_resource_group.env[env].id, role = null, condition = null } },
    { for env in keys(var.environments) : "${env}-plan-state" => { identity = "${env}-plan", scope = module.state.container_ids[env], role = "Storage Blob Data Reader", condition = null } },
    { for env in keys(var.environments) : "${env}-apply-rg" => { identity = "${env}-apply", scope = azurerm_resource_group.env[env].id, role = "Contributor", condition = null } },
    { for env in keys(var.environments) : "${env}-apply-rbac" => { identity = "${env}-apply", scope = azurerm_resource_group.env[env].id, role = "Role Based Access Control Administrator", condition = local.rbac_condition } },
    { for env in keys(var.environments) : "${env}-apply-state" => { identity = "${env}-apply", scope = module.state.container_ids[env], role = "Storage Blob Data Contributor", condition = null } },
  )
}

resource "azurerm_role_assignment" "ci" {
  for_each             = local.role_assignments
  scope                = each.value.scope
  role_definition_name = each.value.role
  role_definition_id   = each.value.role == null ? azurerm_role_definition.plan.role_definition_resource_id : null
  principal_id         = azuread_service_principal.ci[each.value.identity].object_id
  condition            = each.value.condition
  condition_version    = each.value.condition == null ? null : "2.0"
}

output "ci_identities" {
  value = { for k, app in azuread_application.ci : k => app.client_id }
}
