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
