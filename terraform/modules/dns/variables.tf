variable "zone_id" { type = string }
variable "root_name" { type = string }         # apex, e.g. gjcarberry.uk
variable "cf_domain_name" { type = string }    # e.g. dxxxxx.cloudfront.net
variable "cf_hosted_zone_id" { type = string } # CloudFront hosted zone id
variable "enable_www" {
  type    = bool
  default = true
}

