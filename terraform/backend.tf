terraform {
  required_version = ">= 1.6.0"
  # required_providers {
  #   aws = { source = "hashicorp/aws", version = ">= 5.60" }
  # }
  backend "s3" {
    bucket         = "wa-static-site-tfstate-412717960006"
    key            = "well-architected-static-site/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "wa-static-site-tf-locks"
    encrypt        = true
  }
}
