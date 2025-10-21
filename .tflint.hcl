# ===========================================
#  TFLint configuration for Well-Architected Static Site
# ===========================================

plugin "aws" {
  enabled = true
  version = "~> 0.35"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"

  # Match your deployment region
  region = "eu-west-2"
}

config {
  format         = "default"
  call_module_type = "all"
}

# --- Rule tuning ---
rule "aws_s3_bucket_invalid_region" {
  enabled = false # avoid noise for cross-region (us-east-1 ACM)
}

rule "aws_acm_certificate_invalid_region" {
  enabled = false # intentionally us-east-1 for CloudFront
}

rule "aws_instance_invalid_type" {
  enabled = false # not using EC2
}

rule "aws_iam_policy_document_missing_version" {
  enabled = false # Terraform provider adds automatically
}
