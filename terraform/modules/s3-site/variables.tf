variable "project_name" { type = string }
variable "account_id" { type = string }
variable "region" { type = string }
variable "tags" { type = map(string) }

variable "site_bucket_name_override" {
  description = "Optional fixed bucket name; default uses project/account."
  type        = string
  default     = ""
}
