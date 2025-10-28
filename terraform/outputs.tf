# --- S3 ---
output "bucket_name" {
  value       = module.s3_site.site_bucket_name
  description = "Primary site bucket name"
}

output "logging_bucket_name" {
  value       = module.s3_site.logs_bucket_name
  description = "Logs bucket name"
}

# --- CloudFront ---
output "cloudfront_domain_name" {
  value       = module.cloudfront.distribution_domain_name
  description = "CloudFront distribution domain"
}

output "cloudfront_distribution_id" {
  value       = module.cloudfront.distribution_id
  description = "CloudFront distribution ID"
}

output "cloudfront_url" {
  value       = "https://${module.cloudfront.distribution_domain_name}"
  description = "Convenience URL to the dist"
}

# --- WAF ---
output "waf_web_acl_arn" {
  value       = module.waf.waf_arn
  description = "WAFv2 Web ACL ARN (CloudFront scope)"
}

# --- ACM ---
output "acm_certificate_arn" {
  value       = module.cert.acm_certificate_arn
  description = "ACM cert ARN (us-east-1)"
}

# --- GitHub CI ---
output "deploy_role_arn" {
  value       = module.ci_github.deploy_role_arn
  description = "OIDC deploy role for GitHub Actions"
}

output "github_oidc_provider_arn" {
  value       = module.ci_github.oidc_provider_arn
  description = "GitHub OIDC provider ARN"
}

output "oidc_provider_arn" {
  value       = module.ci_github.oidc_provider_arn
  description = "GitHub OIDC provider ARN"
}

# --- WAF Logs Bucket (us-east-1) ---
output "waf_logs_bucket_arn" {
  value       = module.waf.waf_logs_bucket_arn
  description = "ARN of the dedicated us-east-1 bucket for WAF logs"
}

output "waf_logs_bucket_name" {
  value       = module.waf.waf_logs_bucket_name
  description = "WAF logs S3 bucket name (us-east-1)."
}

output "waf_firehose_arn" {
  value       = module.waf.waf_firehose_arn
  description = "WAF logs Firehose ARN (us-east-1)."
}