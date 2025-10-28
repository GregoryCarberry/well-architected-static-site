variable "project_name" {
  description = "Name used for tagging and resource naming."
  type        = string
}

variable "site_bucket_name" {
  description = "Name of the S3 bucket hosting the site (REST endpoint)."
  type        = string
}

variable "site_bucket_arn" {
  description = "ARN of the S3 site bucket."
  type        = string
}

variable "site_bucket_region" {
  description = "Region of the S3 site bucket (for REST endpoint domain)."
  type        = string
}

variable "enable_custom_domain" {
  description = "Whether to attach custom domain and ACM cert."
  type        = bool
  default     = false
}

variable "aliases" {
  description = "Custom domain aliases (e.g., [example.com, www.example.com])."
  type        = list(string)
  default     = []
}

variable "acm_cert_arn" {
  description = "ACM certificate ARN (us-east-1) for CloudFront."
  type        = string
  default     = null
}

variable "waf_arn" {
  description = "WAFv2 Web ACL ARN to associate with distribution."
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront price class (e.g., PriceClass_100, _200, All)."
  type        = string
  default     = "PriceClass_100"
}

variable "default_root_object" {
  description = "Default root object."
  type        = string
  default     = "index.html"
}

variable "enable_access_logging" {
  description = "Enable CloudFront access logging."
  type        = bool
  default     = false
}

variable "logs_bucket_name" {
  description = "S3 bucket name for CloudFront access logs (no ARN)."
  type        = string
  default     = ""
}

variable "logs_prefix" {
  description = "Prefix for CloudFront access logs."
  type        = string
  default     = "cloudfront/"
}

variable "enable_www_redirect" {
  description = "Attach a CF Function to redirect www.* hostnames to apex."
  type        = bool
  default     = true
}

variable "cf_api_region" {
  description = "Pseudo-region for CloudFront ARNs (always us-east-1 for API)."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
