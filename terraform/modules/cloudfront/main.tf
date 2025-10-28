terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = [aws.global, aws.regional]
    }
  }
}

# ---------------------------
# Origin Access Control (OAC)
# ---------------------------
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_name}-oac"
  provider                          = aws.global
  description                       = "OAC for ${var.project_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --------------------------------
# Security Response Headers Policy
# --------------------------------
resource "aws_cloudfront_response_headers_policy" "security" {
  name     = "${var.project_name}-security-headers"
  provider = aws.global

  # Supported nested block
  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "no-referrer"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    xss_protection {
      protection = true
      mode_block = true
      override   = true
    }
  }

  # "Permissions-Policy" via custom header (provider does not accept a permissions_policy block)
  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      value    = "geolocation=(), microphone=(), camera=(), payment=()"
      override = true
    }
  }
}

# ----------------------------------------
# Optional CloudFront Function (www -> apex)
# ----------------------------------------
locals {
  enable_www_redirect = var.enable_www_redirect && length(var.aliases) > 0
}

resource "aws_cloudfront_function" "www_to_root" {
  provider = aws.global
  count    = local.enable_www_redirect ? 1 : 0
  name     = "${var.project_name}-www-to-root"
  runtime  = "cloudfront-js-1.0"
  comment  = "Redirect www.* to apex domain"

  code = <<-JS
    function handler(event) {
      var req = event.request;
      var host = (req.headers.host && req.headers.host.value) || "";
      if (host.startsWith("www.")) {
        var apex = host.substring(4);
        var qs = "";
        if (req.querystring && Object.keys(req.querystring).length > 0) {
          var parts = [];
          for (var k in req.querystring) {
            var v = req.querystring[k];
            if (v && v.value !== undefined) {
              parts.push(k + "=" + v.value);
            }
          }
          if (parts.length > 0) {
            qs = "?" + parts.join("&");
          }
        }
        var location = "https://" + apex + req.uri + qs;
        return {
          statusCode: 301,
          statusDescription: "Moved Permanently",
          headers: { "location": { "value": location } }
        };
      }
      return req;
    }
  JS
}

# -----------------------------
# CloudFront Distribution (S3)
# -----------------------------
# Use S3 REST endpoint with OAC
locals {
  s3_origin_domain_name = "${var.site_bucket_name}.s3.${var.site_bucket_region}.amazonaws.com"
}

resource "aws_cloudfront_distribution" "this" {
  provider            = aws.global
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.project_name
  price_class         = var.price_class
  web_acl_id          = var.waf_arn
  default_root_object = var.default_root_object

  aliases = var.enable_custom_domain ? var.aliases : []

  origin {
    origin_id                = "s3-origin"
    domain_name              = local.s3_origin_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # AWS managed cache policy for static sites
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized

    # Attach our security headers policy
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    # Only create association when redirect is enabled
    dynamic "function_association" {
      for_each = local.enable_www_redirect ? [1] : []
      content {
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.www_to_root[0].arn
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.enable_custom_domain ? false : true
    acm_certificate_arn            = var.enable_custom_domain ? var.acm_cert_arn : null
    ssl_support_method             = var.enable_custom_domain ? "sni-only" : null
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  #   dynamic "logging_config" {
  #     for_each = var.enable_access_logging && var.logs_bucket_name != "" ? [1] : []
  #     content {
  #       bucket          = "${var.logs_bucket_name}.s3.amazonaws.com"
  #       include_cookies = false
  #       prefix          = var.logs_prefix
  #     }
  #   }

  tags = var.tags
}

# --------------------------------------------
# S3 bucket policy granting access from OAC
# (no circular dependency: wildcard SourceArn)
# --------------------------------------------
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "site_policy" {
  statement {
    sid     = "AllowCloudFrontReadViaOAC"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${var.site_bucket_arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    # Correct CloudFront ARN format: no region
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.this.id}"]
    }

    # Extra guard: ensure only your account's distributions can use it
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid       = "AllowBucketListForCloudFront"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.site_bucket_arn]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.this.id}"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  provider = aws.regional
  bucket   = var.site_bucket_name
  policy   = data.aws_iam_policy_document.site_policy.json
}