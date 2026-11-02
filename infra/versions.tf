terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.12"
    }
  }

  # Settings come from envs/<env>/backend.hcl: terraform init -backend-config=../envs/<env>/backend.hcl
  backend "azurerm" {}
}

# Subscription from ARM_SUBSCRIPTION_ID; auth via OIDC in CI (ARM_USE_OIDC) or Azure CLI locally.
provider "azurerm" {
  features {}
  # CI identities are scoped to one resource group; providers are registered by bootstrap
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}
