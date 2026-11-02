output "container_app_environment_id" {
  value       = azurerm_container_app_environment.this.id
  description = "Container Apps environment the services run in"
}

output "container_registry_id" {
  value       = azurerm_container_registry.this.id
  description = "Container registry ID"
}

output "container_registry_login_server" {
  value       = azurerm_container_registry.this.login_server
  description = "Container registry login server"
}

output "key_vault_id" {
  value       = azurerm_key_vault.this.id
  description = "Key Vault ID"
}

output "key_vault_uri" {
  value       = azurerm_key_vault.this.vault_uri
  description = "Key Vault URI"
}

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.this.id
  description = "Log Analytics workspace ID"
}
