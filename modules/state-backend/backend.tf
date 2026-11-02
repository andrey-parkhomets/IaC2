module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.3.0"
  suffix  = var.name_suffix
}

resource "azurerm_resource_group" "this" {
  name     = join("-", [module.naming.resource_group.name, "tfstate"])
  location = var.location

  tags = merge(var.tags, { resource = "rg" })
}

resource "azurerm_storage_account" "this" {
  name                          = module.naming.storage_account.name_unique
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = var.public_network_access_enabled
  # Entra ID only: account keys are long-lived credentials
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = var.storage_account_delete_retention_period
    }
    versioning_enabled = var.storage_account_versioning_enabled
  }

  tags = merge(var.tags, { resource = "storage" })
}

resource "azurerm_storage_container" "this" {
  for_each              = var.environments
  name                  = each.key
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# Backends use Entra ID auth (use_azuread_auth), which requires a data plane role
resource "azurerm_role_assignment" "state_contributor" {
  for_each             = var.state_contributor_principal_ids
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.key
}

resource "azurerm_management_lock" "rg_rm_lock" {
  name       = "TerraformStateRGLockCanNotDelete"
  scope      = azurerm_resource_group.this.id
  lock_level = "CanNotDelete"
  depends_on = [azurerm_storage_container.this]
}

###############################################################################
## Soft delete policy
###############################################################################

resource "azurerm_policy_definition" "soft_delete_policy" {
  count        = var.policies_enabled && !var.policy_definition_exists ? 1 : 0
  name         = "SoftDeleteEnabled"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Storage account must have Blob soft delete enabled"

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Storage"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts/blobServices"
        },
        {
          field     = "Microsoft.Storage/storageAccounts/blobServices/deleteRetentionPolicy.enabled"
          notEquals = "true"
        },
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })

  parameters = jsonencode({
    effect = {
      type         = "String"
      defaultValue = "Deny"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable execution of the policy"
      }
    }
  })
}

data "azurerm_policy_definition" "soft_delete_policy" {
  count = var.policies_enabled && var.policy_definition_exists ? 1 : 0
  name  = "SoftDeleteEnabled"
}

resource "azurerm_resource_policy_assignment" "this" {
  count                = var.policies_enabled ? 1 : 0
  name                 = "soft-delete-policy-assignment"
  resource_id          = azurerm_storage_account.this.id
  policy_definition_id = one(concat(data.azurerm_policy_definition.soft_delete_policy[*].id, azurerm_policy_definition.soft_delete_policy[*].id))
}
