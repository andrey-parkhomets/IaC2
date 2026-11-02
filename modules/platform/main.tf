# Shared per-environment platform: logging, container runtime, registry, secrets.
# Services (modules/container-service) are deployed on top of it.

module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.3.0"
  suffix  = [var.project, var.environment]
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = module.naming.log_analytics_workspace.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

resource "azurerm_container_app_environment" "this" {
  name                       = module.naming.container_app_environment.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  tags                       = var.tags
}

resource "azurerm_container_registry" "this" {
  name                = module.naming.container_registry.name_unique
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  # Pulls use managed identities (AcrPull), pushes use CI OIDC identities
  admin_enabled = false
  tags          = var.tags
}

resource "azurerm_key_vault" "this" {
  name                       = module.naming.key_vault.name_unique
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = var.key_vault_soft_delete_days
  purge_protection_enabled   = var.key_vault_purge_protection
  tags                       = var.tags
}

data "azurerm_client_config" "current" {}

# Audit and platform logs of the registry and the vault go to the same workspace
resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = {
    acr       = azurerm_container_registry.this.id
    key_vault = azurerm_key_vault.this.id
  }
  name                       = "to-log-analytics"
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
