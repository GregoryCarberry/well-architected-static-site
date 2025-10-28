data "aws_caller_identity" "current" {}

locals {
  site_bucket_name = var.site_bucket_name_override != "" ? var.site_bucket_name_override : "${var.project_name}-site-${var.account_id}"
  logs_bucket_name = "${var.project_name}-logs-${var.account_id}"
}

# Site bucket (private; served via CloudFront OAC)
resource "aws_s3_bucket" "site" {
  bucket = local.site_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Logs bucket
resource "aws_s3_bucket" "logs" {
  bucket = local.logs_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
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

# Lifecycle for logs (tune as desired)
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter { prefix = "cloudfront/" }

    expiration {
      days = 90
    }
  }

  rule {
    id     = "expire-waf-logs"
    status = "Enabled"

    filter { prefix = "waf/" }

    expiration {
      days = 30
    }
  }
}

# Server access logging for the site bucket (to logs bucket)
resource "aws_s3_bucket_logging" "site_to_logs" {
  bucket        = aws_s3_bucket.site.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access/"
}
