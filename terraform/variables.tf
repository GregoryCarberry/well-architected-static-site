variable "project_name" {
  type        = string
  default     = "wa-static-site"
  description = "Name prefix for resources."
}

variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "Primary region for S3 and general resources."
}

# Minimal WAF switch (leave true; can be toggled off if needed)
variable "enable_waf" {
  type        = bool
  default     = true
}

variable "github_owner" {
  description = "GitHub org/user that owns the repo (e.g., GregoryCarberry)"
  type        = string
}

variable "github_repo" {
  description = "Repo name (e.g., well-architected-static-site)"
  type        = string
}

variable "github_branch" {
  description = "Branch that can deploy (e.g., main)"
  type        = string
  default     = "main"
}
