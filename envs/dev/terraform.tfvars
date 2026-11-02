environment = "dev"

acr_sku                    = "Basic"
log_retention_days         = 30
key_vault_soft_delete_days = 7
key_vault_purge_protection = false

services = {
  api = {
    # Placeholder until the application pipeline pushes the real image to ACR
    image        = "mcr.microsoft.com/k8se/quickstart:latest"
    target_port  = 80
    min_replicas = 0 # scale to zero when idle
    max_replicas = 2
    env = {
      ASPNETCORE_ENVIRONMENT = "Development"
    }
  }
}
