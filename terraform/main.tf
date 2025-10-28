# ------------------------------------------------------------
# Root wiring — composes modules (keep resources in modules/)
# ------------------------------------------------------------

# Random suffix for globally unique bucket names
resource "random_id" "suffix" {
  byte_length = 2
}

locals {
  project_name_suffixed = "${var.project_name}-${substr(random_id.suffix.hex, 0, 4)}"
}

data "aws_caller_identity" "current" {}

# Route 53 zone for your domain (adjust if you use a different lookup)
data "aws_route53_zone" "this" {
  name = var.domain_name
}

# --- S3: site + logs
module "s3_site" {
  source       = "./modules/s3-site"
  project_name = local.project_name_suffixed
  account_id   = data.aws_caller_identity.current.account_id
  region       = var.region
  tags         = local.common_tags
}

# --- WAF (CloudFront scope => us-east-1 API)
module "waf" {
  source          = "./modules/waf"
  logs_bucket_arn = module.s3_site.logs_bucket_arn
  logs_prefix     = "waf/"
  tags            = local.common_tags

  providers = {
    aws.global = aws.us_east_1 # WAF/global API
    # aws.regional = aws           # same region as your S3 logs bucket
  }
}

# --- ACM certificate + DNS validation (us-east-1 for CloudFront)
module "cert" {
  source      = "./modules/cert"
  domain_name = var.domain_name
  san_names   = ["www.${var.domain_name}"]
  zone_id     = data.aws_route53_zone.this.zone_id
  tags        = local.common_tags

  providers = { aws = aws.us_east_1 }
}

# --- CloudFront distribution (with OAC, headers, optional www->apex redirect)
module "cloudfront" {
  source             = "./modules/cloudfront"
  project_name       = var.project_name
  site_bucket_name   = module.s3_site.site_bucket_name
  site_bucket_arn    = module.s3_site.site_bucket_arn
  site_bucket_region = var.region

  enable_custom_domain = var.enable_custom_domain
  aliases              = var.enable_custom_domain ? [var.domain_name, "www.${var.domain_name}"] : []
  acm_cert_arn         = var.enable_custom_domain ? module.cert.acm_certificate_arn : null
  waf_arn              = module.waf.waf_arn

  price_class           = var.price_class
  default_root_object   = "index.html"
  enable_access_logging = true
  logs_bucket_name      = module.s3_site.logs_bucket_name
  logs_prefix           = "cloudfront/"
  enable_www_redirect   = true

  tags = local.common_tags

  providers = {
    aws.global   = aws.us_east_1 # CF API
    aws.regional = aws           # same region as S3 bucket
  }

}

# --- DNS: alias apex + www to CloudFront
module "dns" {
  source            = "./modules/dns"
  zone_id           = data.aws_route53_zone.this.zone_id
  root_name         = var.domain_name
  cf_domain_name    = module.cloudfront.distribution_domain_name
  cf_hosted_zone_id = module.cloudfront.hosted_zone_id
  enable_www        = true
}

# --- GitHub OIDC + deploy role/policy
module "ci_github" {
  source         = "./modules/ci-github"
  project_name   = var.project_name
  repo_full_name = var.github_repo
  tags           = local.common_tags
}

# --- Monthly cost budget (GBP)
module "budget" {
  source       = "./modules/budget"
  limit_amount = var.budget_limit
  emails       = var.budget_email
  tags         = local.common_tags
}
