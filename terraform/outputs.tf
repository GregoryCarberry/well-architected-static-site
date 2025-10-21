output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.this.id
}

output "deploy_role_arn" {
  value       = aws_iam_role.gh_actions_deploy.arn
  description = "IAM role ARN GitHub Actions should assume."
}

# WAF and logging visibility outputs
output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL protecting the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.web_acl_id
}

output "logging_bucket_name" {
  description = "Name of the S3 bucket storing CloudFront logs"
  value       = aws_s3_bucket.logs.bucket
}

# IAM / CI visibility for GitHub OIDC
output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider used for CI/CD"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_deploy_role_name" {
  description = "Name of the IAM role assumed by GitHub Actions"
  value       = "${var.project_name}-gh-deploy"
}

# DNS + ACM context for custom domains
output "domain_name" {
  description = "Primary domain name for the site"
  value       = var.domain_name
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate in us-east-1"
  value       = aws_acm_certificate.cf[0].arn
}

# Full CloudFront URL for easy access
output "cloudfront_url" {
  description = "Full HTTPS URL to the CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.this.domain_name}"
}
