# One containerised service on the shared platform: its own identity, least-privilege
# access to the registry and the vault, and the Container App itself.

resource "azurerm_user_assigned_identity" "this" {
  name                = "id-${var.name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_container_app" "this" {
  name                         = "ca-${var.name}-${var.environment}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  registry {
    server   = var.container_registry_login_server
    identity = azurerm_user_assigned_identity.this.id
  }

  # Values live in Key Vault (set out of band); the app only gets references
  dynamic "secret" {
    for_each = var.key_vault_secrets
    content {
      name                = secret.key
      key_vault_secret_id = "${var.key_vault_uri}secrets/${secret.value}"
      identity            = azurerm_user_assigned_identity.this.id
    }
  }

  ingress {
    external_enabled = var.external_ingress
    target_port      = var.target_port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.env
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.key_vault_secrets
        content {
          name        = upper(replace(env.key, "-", "_"))
          secret_name = env.key
        }
      }
    }
  }

  lifecycle {
    # The image tag is owned by the application's release pipeline, not by infra
    ignore_changes = [template[0].container[0].image]
  }

  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.key_vault_secrets_user,
  ]
}
