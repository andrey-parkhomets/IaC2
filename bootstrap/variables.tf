variable "subscription_id" {
  type        = string
  description = "Subscription hosting the state account and the environments"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "project" {
  type        = string
  description = "Short project name; environment resource groups are rg-<project>-<env>"
}

variable "github_owner" {
  type        = string
  description = "GitHub user or organisation"
}

variable "github_repository" {
  type        = string
  description = "Repository name"
}

variable "github_oidc_subject_prefix" {
  type        = string
  description = "OIDC sub prefix of the repo: gh api repos/<owner>/<repo>/actions/oidc/customization/sub -q .sub_claim_prefix"
}

variable "environments" {
  type = map(object({
    reviewers = optional(list(string), [])
  }))
  description = "Environments and the GitHub users who must approve their applies. Adding an environment starts here"
}

variable "admin_principal_ids" {
  type        = set(string)
  description = "Object IDs of people running bootstrap; get read/write on all state"
}

variable "required_status_checks" {
  type        = list(string)
  default     = []
  description = "Checks that must pass before merging to main"
}
