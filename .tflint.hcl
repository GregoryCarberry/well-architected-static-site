# ===========================================
#  TFLint configuration for Well-Architected Static Site
# ===========================================

plugin "aws" {
  enabled = true
  version = "0.35.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"

  # Match your deployment region
  region = "eu-west-2"
}

config {
  format         = "default"
  call_module_type = "all"
}

