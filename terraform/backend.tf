terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60"
    }
  }

  # OPTIONAL: uncomment and fill when you have a remote backend ready
  # backend "s3" {
  #   bucket         = "<your-tfstate-bucket>"
  #   key            = "well-architected-static-site/terraform.tfstate"
  #   region         = "eu-west-1"
  #   dynamodb_table = "<your-lock-table>"
  #   encrypt        = true
  # }
}
