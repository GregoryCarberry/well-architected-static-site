terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.global]
    }
  }
}

# ------------------------------------------------------------
# WAFv2 (CloudFront scope) + Firehose -> S3 (all in us-east-1)
# ------------------------------------------------------------

data "aws_caller_identity" "current" {
  provider = aws.global
}

# -----------------
# WAF logs bucket (us-east-1)
# -----------------
resource "aws_s3_bucket" "waf_logs" {
  provider = aws.global
  bucket   = "waf-logs-${data.aws_caller_identity.current.account_id}-use1"
  tags     = var.tags
}

resource "aws_s3_bucket_ownership_controls" "waf_logs" {
  provider = aws.global
  bucket   = aws_s3_bucket.waf_logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logs" {
  provider = aws.global
  bucket   = aws_s3_bucket.waf_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  provider = aws.global
  bucket   = aws_s3_bucket.waf_logs.id

  rule {
    id     = "expire-waf-logs"
    status = "Enabled"
    filter {
      prefix = var.logs_prefix
    }
    expiration {
      days = 90
    }
  }
}

# -----------------
# WAFv2 Web ACL (CloudFront scope)
# -----------------
resource "aws_wafv2_web_acl" "this" {
  provider    = aws.global
  name        = "waf-global-cloudfront"
  description = "Global WAF - CloudFront scope"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-global"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-CommonRuleSet"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common"
      sampled_requests_enabled   = true
    }

    override_action {
      none {}
    }
  }

  rule {
    name     = "AWS-AmazonIpReputationList"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "iprep"
      sampled_requests_enabled   = true
    }

    override_action {
      none {}
    }
  }

  rule {
    name     = "AWS-BotControl"
    priority = 3

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "bot"
      sampled_requests_enabled   = true
    }

    override_action {
      none {}
    }
  }

  tags = var.tags
}

# -----------------
# Firehose role & policy (us-east-1)
# -----------------
data "aws_iam_policy_document" "firehose_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "firehose" {
  provider           = aws.global
  name               = "waf-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "firehose_policy" {
  statement {
    sid = "S3WriteAccessForFirehose"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      aws_s3_bucket.waf_logs.arn,
      "${aws_s3_bucket.waf_logs.arn}/*"
    ]
  }

  statement {
    sid       = "CloudWatchLogsWrite"
    actions   = ["logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "firehose" {
  provider = aws.global
  name     = "waf-firehose-policy"
  policy   = data.aws_iam_policy_document.firehose_policy.json
}

resource "aws_iam_role_policy_attachment" "firehose_attach" {
  provider   = aws.global
  role       = aws_iam_role.firehose.name
  policy_arn = aws_iam_policy.firehose.arn
}

# -----------------
# Firehose -> S3 (us-east-1)
# -----------------
resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  provider    = aws.global
  name        = "aws-waf-logs-${aws_wafv2_web_acl.this.name}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose.arn
    bucket_arn         = aws_s3_bucket.waf_logs.arn
    prefix             = var.logs_prefix
    buffering_interval = 300
    buffering_size     = 5
    compression_format = "GZIP"
  }

  tags = var.tags
}

# -----------------
# Attach WAF logging to Firehose
# -----------------
resource "aws_wafv2_web_acl_logging_configuration" "this" {
  provider                = aws.global
  resource_arn            = aws_wafv2_web_acl.this.arn
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_logs.arn]

  depends_on = [
    aws_kinesis_firehose_delivery_stream.waf_logs
  ]
}
