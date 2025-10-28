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
  type    = bool
  default = true
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

variable "enable_custom_domain" {
  description = "Enable ACM + custom domain wiring"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Root domain (e.g., example.com) that lives in Route 53"
  type        = string
}

variable "budget_amount" {
  description = "Monthly budget limit for this project"
  type        = number
  default     = 3 # £3 or $3 depending on your account currency
}

variable "budget_currency" {
  description = "Currency code for the budget (must match your account currency)"
  type        = string
  default     = "USD" # set to "GBP" if your account is billed in GBP
}

variable "budget_email" {
  description = "Email addresses to notify for budget alerts"
  type        = list(string)
  default     = ["Carberry.GJ@gmail.com"] # change/add as you like
}

variable "budget_limit" {
  description = "Monthly cost budget amount (GBP)."
  type        = number
  default     = 5
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"
}