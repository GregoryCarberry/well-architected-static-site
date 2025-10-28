# terraform {
#   required_version = ">= 1.5.0"
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = ">= 5.0"
#     }
#   }
# }

provider "aws" {
  region = var.region
}

# CloudFront, ACM, WAF (global APIs) are surfaced via us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Keep if you actively use eu-west-2 specifically elsewhere
provider "aws" {
  alias  = "eu_west_2"
  region = "eu-west-2"
}
