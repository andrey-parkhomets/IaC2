output "storage_account_id" {
  value       = azurerm_storage_account.this.id
  description = "The ID of storage account."
}

output "storage_account_name" {
  value       = azurerm_storage_account.this.name
  description = "The name of storage account."
}

output "resource_group_name" {
  value       = azurerm_resource_group.this.name
  description = "The name of the state resource group."
}

output "backend_config" {
  value = {
    for env, container in azurerm_storage_container.this : env => {
      subscription_id      = data.azurerm_subscription.current.subscription_id
      resource_group_name  = azurerm_resource_group.this.name
      storage_account_name = azurerm_storage_account.this.name
      container_name       = container.name
      key                  = "${env}.tfstate"
      use_azuread_auth     = true
    }
  }
  description = "Partial azurerm backend configuration per environment, ready to be written to backend.hcl."
}

output "container_ids" {
  value       = { for env, c in azurerm_storage_container.this : env => c.id }
  description = "Resource manager IDs of the state containers, for container-scoped role assignments."
}
