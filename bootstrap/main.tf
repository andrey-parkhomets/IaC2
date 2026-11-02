# Run by an admin, locally, rarely. Creates everything CI needs and cannot create itself:
# state storage, environment resource groups, CI identities and the GitHub environments.

module "state" {
  source = "../modules/state-backend"

  location                        = var.location
  name_suffix                     = [var.project]
  environments                    = concat(["bootstrap"], keys(var.environments))
  state_contributor_principal_ids = var.admin_principal_ids
  # Created in this subscription by the earlier IaC project
  policy_definition_exists = true
}

resource "azurerm_resource_group" "env" {
  for_each = var.environments
  name     = "rg-${var.project}-${each.key}"
  location = var.location
  tags = {
    project     = var.project
    environment = each.key
    managed_by  = "terraform-bootstrap"
  }
}

output "backend_config" {
  value = module.state.backend_config
}
