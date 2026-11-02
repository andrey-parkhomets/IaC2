variable "project" {
  type        = string
  description = "Short project name used in resource names"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod, ...)"
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group of the environment (created by bootstrap)"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "acr_sku" {
  type        = string
  default     = "Basic"
  description = "Container registry SKU: Basic, Standard or Premium"
}

variable "log_retention_days" {
  type        = number
  default     = 30
  description = "Log Analytics retention in days"
}

variable "key_vault_soft_delete_days" {
  type        = number
  default     = 7
  description = "Key Vault soft delete retention in days (7-90)"
}

variable "key_vault_purge_protection" {
  type        = bool
  default     = false
  description = "Prevent purging deleted vaults/secrets before retention ends. Irreversible once enabled"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for all resources"
}
