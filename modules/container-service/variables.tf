variable "name" {
  type        = string
  description = "Service name, lowercase letters, digits and hyphens"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.name))
    error_message = "Service name must be 2-21 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod, ...)"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group of the environment"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "container_app_environment_id" {
  type        = string
  description = "Container Apps environment from the platform module"
}

variable "container_registry_id" {
  type        = string
  description = "Registry the service pulls from"
}

variable "container_registry_login_server" {
  type        = string
  description = "Registry login server"
}

variable "key_vault_id" {
  type        = string
  description = "Vault holding the service secrets"
}

variable "key_vault_uri" {
  type        = string
  description = "Vault URI, used to build secret references"
}

variable "image" {
  type        = string
  description = "Initial container image. Later image updates come from the application pipeline"
}

variable "target_port" {
  type        = number
  default     = 80
  description = "Port the container listens on"
}

variable "external_ingress" {
  type        = bool
  default     = true
  description = "Expose the service publicly"
}

variable "cpu" {
  type        = number
  default     = 0.25
  description = "vCPU per replica"
}

variable "memory" {
  type        = string
  default     = "0.5Gi"
  description = "Memory per replica, must match the CPU ratio (0.25 -> 0.5Gi)"
}

variable "min_replicas" {
  type        = number
  default     = 0
  description = "Minimum replicas (0 scales to zero)"
}

variable "max_replicas" {
  type        = number
  default     = 2
  description = "Maximum replicas"
}

variable "env" {
  type        = map(string)
  default     = {}
  description = "Plain environment variables"
}

variable "key_vault_secrets" {
  type        = map(string)
  default     = {}
  description = "App secret name => Key Vault secret name. Exposed to the container as an upper-case env var"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for all resources"
}
