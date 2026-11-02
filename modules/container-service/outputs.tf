output "fqdn" {
  value       = azurerm_container_app.this.ingress[0].fqdn
  description = "Public (or environment-internal) FQDN of the service"
}

output "identity_principal_id" {
  value       = azurerm_user_assigned_identity.this.principal_id
  description = "Principal ID of the service identity"
}
