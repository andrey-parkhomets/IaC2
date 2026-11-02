variable "location" {
  type        = string
  description = "Region to deploy resources to"
}

variable "name_suffix" {
  type        = list(string)
  description = "Resource name suffix - please only use lowercase characters"
}

variable "environments" {
  type        = set(string)
  description = "Environments hosted in this subscription. A state container is created for each of them"

  validation {
    condition     = alltrue([for env in var.environments : can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", env))])
    error_message = "Environment names must be valid container names: 3-63 lowercase letters, digits or hyphens."
  }
}

variable "state_contributor_principal_ids" {
  type        = set(string)
  default     = []
  description = "Object IDs granted Storage Blob Data Contributor on the state account (users running bootstrap, CI identity)"
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Enable or disable public network access to the storage account"
}

variable "storage_account_delete_retention_period" {
  type        = number
  default     = 30
  description = "Period in days for blob delete retention"
}

variable "storage_account_versioning_enabled" {
  type        = bool
  default     = true
  description = "Bool flag for blob versioning enable/disable"
}

variable "policies_enabled" {
  type        = bool
  default     = true
  description = "Bool flag for applying the soft delete Azure policy"
}

variable "policy_definition_exists" {
  type        = bool
  default     = false
  description = "Set to true if the soft delete policy definition already exists in the subscription"
}

variable "tags" {
  type = map(string)
  default = {
    source = "terraform"
  }
  description = "Additional tags for all resources"
}
