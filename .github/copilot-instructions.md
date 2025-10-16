# AI Agent Instructions for Well-Architected Static Site

This project implements a well-architected static website hosting solution on AWS using Terraform. Below are key patterns and conventions to follow when working with this codebase.

## Architecture Overview

- **Component Structure**:
  - `site/`: Contains static website files (HTML/CSS/JS)
  - `terraform/`: IaC for AWS infrastructure
    - Private S3 bucket (origin)
    - CloudFront distribution with Origin Access Control (OAC)
    - WAFv2 with managed rules (optional)

## Infrastructure Patterns

### AWS Resource Naming
- Resources follow `${var.project_name}-resource-${account_id}` pattern
- Example: S3 bucket naming in `terraform/main.tf`: `${var.project_name}-site-${data.aws_caller_identity.current.account_id}`

### Multi-Region Setup
- Primary region (configurable, default: eu-west-1): S3 and general resources
- us-east-1: Global services (CloudFront/WAF)
- Use appropriate provider blocks when adding global resources:
  ```terraform
  provider "aws" {
    alias  = "us_east_1"
    region = "us-east-1"
  }
  ```

### Security Patterns
1. S3 Bucket:
   - Always private with public access blocked
   - Versioning enabled by default
2. CloudFront:
   - Uses Origin Access Control (OAC) for S3 access
   - No direct S3 access allowed
3. WAF:
   - Enabled by default (can be disabled via `enable_waf` variable)
   - Uses AWS managed rule sets:
     - AWSManagedRulesCommonRuleSet
     - AWSManagedRulesKnownBadInputsRuleSet

## Development Workflow

### Local Development
1. Preview static site locally by opening `site/index.html` in a browser
2. Edit static content in `site/` directory
3. Test Terraform changes:
   ```bash
   cd terraform
   terraform init
   terraform plan
   ```

### Deployment
1. Ensure AWS credentials are configured
2. Apply infrastructure changes:
   ```bash
   cd terraform
   terraform apply
   ```
3. Upload website content to S3 bucket (use output variable from Terraform)

## Key Files
- `terraform/main.tf`: Core infrastructure definition
- `terraform/variables.tf`: Configuration variables with defaults
- `site/index.html`: Example static site with embedded styles