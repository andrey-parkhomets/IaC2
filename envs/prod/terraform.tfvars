environment = "prod"

acr_sku                    = "Standard"
log_retention_days         = 90
key_vault_soft_delete_days = 90
key_vault_purge_protection = true

services = {
  api = {
    # Placeholder until the application pipeline pushes the real image to ACR
    image        = "mcr.microsoft.com/k8se/quickstart:latest"
    target_port  = 80
    cpu          = 0.5
    memory       = "1Gi"
    min_replicas = 1 # no cold starts in prod
    max_replicas = 5
    env = {
      ASPNETCORE_ENVIRONMENT = "Production"
    }
  }
}
