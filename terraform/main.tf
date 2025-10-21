provider "aws" {
  region = var.region
}

# Global services (CloudFront/WAF) live in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# -----------------------------
# S3 bucket (private, versioned)
# -----------------------------
resource "aws_s3_bucket" "site" {
  bucket = "${var.project_name}-site-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------- Logging bucket ----------
resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-logs-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudFront standard logs require ACL grants (can’t use bucket-owner-enforced)
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  bucket     = aws_s3_bucket.logs.id
  acl        = "log-delivery-write" # grants WRITE/READ_ACP to the CloudFront log delivery group
  depends_on = [aws_s3_bucket_ownership_controls.logs]
}

# Limit the budget scope to services used in this static site
locals {
  budget_services = [
    "Amazon CloudFront",
    "Amazon Route 53",
    "AWS WAF",
    "Amazon Simple Storage Service"
  ]
}

resource "aws_budgets_budget" "wa_monthly_cost" {
  name         = "wa-static-site-monthly"
  budget_type  = "COST"
  time_unit    = "MONTHLY"
  limit_amount = var.budget_amount
  limit_unit   = var.budget_currency

  # Forecast says we'll exceed 80% of the budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_email
  }

  # Actual spend hits 100% of the budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_email
  }

}

# Logs bucket lifecycle (keep ~90 days)
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs-90d"
    status = "Enabled"

    # Whole-object expiry
    expiration {
      days = 90
    }

    # Keep this ONLY if logs bucket has versioning enabled
    # noncurrent_version_expiration {
    #   noncurrent_days = 90
    # }
  }
}

# Site bucket lifecycle (expire old versions after 30 days)
resource "aws_s3_bucket_lifecycle_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}


resource "aws_s3_bucket_logging" "site_logs" {
  bucket        = aws_s3_bucket.site.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-site/"
}



# -----------------------------
# CloudFront OAC
# -----------------------------
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -----------------------------
# WAFv2 (managed rules) - global
# -----------------------------
resource "aws_wafv2_web_acl" "this" {
  provider    = aws.us_east_1
  count       = var.enable_waf ? 1 : 0
  name        = "${var.project_name}-waf"
  description = "Basic managed rule set for ${var.project_name}"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }
}

# --- Managed cache policy lookups (HTML no-cache; assets optimized) ---
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

# --- CloudFront Function: www -> apex redirect ---
resource "aws_cloudfront_function" "www_to_root" {
  name    = "${var.project_name}-www-to-root"
  runtime = "cloudfront-js-1.0"
  comment = "Redirect www.* to apex"
  publish = true
  code    = <<-EOF
    function handler(event) {
      var req = event.request;
      var host = req.headers.host && req.headers.host.value || "";
      if (host.startsWith("www.")) {
        var toHost = host.substring(4);
        return {
          statusCode: 301,
          statusDescription: "Moved Permanently",
          headers: {
            "location": { "value": "https://" + toHost + req.uri }
          }
        };
      }
      return req;
    }
  EOF
}


# CloudFront Response Headers Policy (security)
resource "aws_cloudfront_response_headers_policy" "security" {
  name    = "${var.project_name}-security-headers"
  comment = "HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy"

  security_headers_config {
    content_security_policy {
      override                = true
      content_security_policy = "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; object-src 'none'; base-uri 'self'; frame-ancestors 'none'; upgrade-insecure-requests"
    }

    strict_transport_security {
      override                   = true
      include_subdomains         = true
      preload                    = true
      access_control_max_age_sec = 63072000
    }

    content_type_options {
      override = true
    }

    frame_options {
      override     = true
      frame_option = "DENY"
    }

    referrer_policy {
      override        = true
      referrer_policy = "no-referrer"
    }
  }

  # Add Permissions-Policy via custom header
  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      value    = "camera=(), microphone=(), geolocation=(), fullscreen=(self)"
      override = true
    }
  }
}


# -----------------------------
# CloudFront Distribution
# -----------------------------
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} distribution"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  logging_config {
    bucket          = aws_s3_bucket.logs.bucket_domain_name # e.g. my-logs-bucket.s3.amazonaws.com
    prefix          = "cloudfront/"
    include_cookies = false
  }


  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # HTML should not be cached aggressively (use managed no-cache policy)
    cache_policy_id = data.aws_cloudfront_cache_policy.caching_disabled.id

    # Attach the response headers policy we created earlier
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    # CloudFront Function for www -> apex redirect
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.www_to_root.arn
    }
  }

  # Long-lived assets under /assets/*
  ordered_cache_behavior {
    path_pattern           = "/assets/*"
    target_origin_id       = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    # Aggressive caching for static assets
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  # Friendly error mapping (S3 private site often returns 403 for missing keys)
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 0
  }

  # ---------- THESE MUST BE AT THE RESOURCE LEVEL ----------
  aliases = var.enable_custom_domain ? [
    var.domain_name,
    "www.${var.domain_name}"
  ] : []

  web_acl_id = var.enable_waf ? aws_wafv2_web_acl.this[0].arn : null

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = !var.enable_custom_domain
    acm_certificate_arn            = var.enable_custom_domain ? aws_acm_certificate_validation.cf[0].certificate_arn : null
    ssl_support_method             = var.enable_custom_domain ? "sni-only" : null
    minimum_protocol_version       = var.enable_custom_domain ? "TLSv1.2_2021" : null
  }
}

# -----------------------------
# S3 policy to allow CloudFront (OAC) reads
# -----------------------------
data "aws_iam_policy_document" "site_policy" {
  statement {
    sid       = "AllowCloudFrontServiceGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.this.id}"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_policy.json
}

# -----------------------------
# GitHub OIDC + Deploy Role
# -----------------------------

# GitHub OIDC provider (once per account; creating another with same URL/thumbprint is harmless)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub's OIDC root CA
}

# Trust policy: allow only this repo/branch to assume the role
data "aws_iam_policy_document" "gh_actions_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# Permissions for deploy: sync to S3 + CF invalidation + read TF state (if you later use remote state)
data "aws_iam_policy_document" "gh_actions_permissions" {
  statement {
    sid    = "S3Sync"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [aws_s3_bucket.site.arn]
  }

  statement {
    sid    = "S3Objects"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }

  statement {
    sid       = "CloudFrontInvalidate"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.this.id}"]
  }

  statement {
    sid       = "CloudFrontList"
    effect    = "Allow"
    actions   = ["cloudfront:ListDistributions"]
    resources = ["*"]
  }

}

resource "aws_iam_role" "gh_actions_deploy" {
  name               = "${var.project_name}-gh-deploy"
  assume_role_policy = data.aws_iam_policy_document.gh_actions_assume_role.json
}

resource "aws_iam_policy" "gh_actions_policy" {
  name   = "${var.project_name}-gh-deploy-policy"
  policy = data.aws_iam_policy_document.gh_actions_permissions.json
}

resource "aws_iam_role_policy_attachment" "gh_actions_attach" {
  role       = aws_iam_role.gh_actions_deploy.name
  policy_arn = aws_iam_policy.gh_actions_policy.arn
}

# -----------------------------
# ACM (DNS validation) in us-east-1 for CloudFront
# -----------------------------
data "aws_route53_zone" "this" {
  count        = var.enable_custom_domain ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "cf" {
  provider          = aws.us_east_1
  count             = var.enable_custom_domain ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = [
    "www.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Create a record for each domain validation option (apex + www)
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cf[0].domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}


resource "aws_acm_certificate_validation" "cf" {
  provider                = aws.us_east_1
  count                   = var.enable_custom_domain ? 1 : 0
  certificate_arn         = aws_acm_certificate.cf[0].arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]

  timeouts {
    create = "45m"
  }
}

# Root (apex) A/AAAA
resource "aws_route53_record" "root_a" {
  count   = var.enable_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "root_aaaa" {
  count   = var.enable_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = var.domain_name
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

# WWW A/AAAA
resource "aws_route53_record" "www_a" {
  count   = var.enable_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  count   = var.enable_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
