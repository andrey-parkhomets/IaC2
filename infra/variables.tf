variable "project" {
  type        = string
  default     = "saasapi"
  description = "Short project name used in resource names"
}

variable "environment" {
  type        = string
  description = "Environment name; must match envs/<env> and the bootstrap environments map"
}

variable "acr_sku" {
  type        = string
  default     = "Basic"
  description = "Container registry SKU"
}

variable "log_retention_days" {
  type        = number
  default     = 30
  description = "Log Analytics retention in days"
}

variable "key_vault_soft_delete_days" {
  type        = number
  default     = 7
  description = "Key Vault soft delete retention in days"
}

variable "key_vault_purge_protection" {
  type        = bool
  default     = false
  description = "Key Vault purge protection (irreversible)"
}

variable "services" {
  type = map(object({
    image             = string
    target_port       = optional(number, 80)
    external_ingress  = optional(bool, true)
    cpu               = optional(number, 0.25)
    memory            = optional(string, "0.5Gi")
    min_replicas      = optional(number, 0)
    max_replicas      = optional(number, 2)
    env               = optional(map(string), {})
    key_vault_secrets = optional(map(string), {})
  }))
  description = "Services deployed in this environment. Adding a service is one entry here"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Extra tags for all resources"
}
