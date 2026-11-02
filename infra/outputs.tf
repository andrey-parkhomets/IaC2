output "service_urls" {
  value       = { for name, s in module.service : name => "https://${s.fqdn}" }
  description = "Service endpoints"
}

output "container_registry_login_server" {
  value       = module.platform.container_registry_login_server
  description = "Registry the application pipeline pushes images to"
}

output "key_vault_uri" {
  value       = module.platform.key_vault_uri
  description = "Vault for service secrets"
}
