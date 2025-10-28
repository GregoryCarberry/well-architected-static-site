terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# -----------------------------------------------------------------------------
# Inputs expected by this module (declared in variables.tf):
#   - var.project_name   : string
#   - var.repo_full_name : string   # e.g., "GregoryCarberry/well-architected-static-site"
#   - var.tags           : map(string)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# GitHub OIDC provider
# -----------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # Current GitHub OIDC thumbprint (HashiCorp docs / AWS examples).
  # If GitHub rotates certs, you may need to add/rotate this value.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Trust policy for GitHub Actions via OIDC
#  - Locks to your repo's main branch
#  - 'aud' must be sts.amazonaws.com
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "gh_oidc_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Accept main branch, any branch, tags, and PRs
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:GregoryCarberry/well-architected-static-site:ref:refs/heads/main",
        "repo:GregoryCarberry/well-architected-static-site:ref:refs/heads/*",
        "repo:GregoryCarberry/well-architected-static-site:ref:refs/tags/*",
        "repo:GregoryCarberry/well-architected-static-site:pull_request"
      ]
    }
  }
}

# -----------------------------------------------------------------------------
# Deploy role assumed by GitHub Actions
# -----------------------------------------------------------------------------
resource "aws_iam_role" "gh_actions_deploy" {
  name               = "wa-static-site-gh-deploy"
  description        = "GitHub Actions deploy role for ${var.project_name} via OIDC"
  assume_role_policy = data.aws_iam_policy_document.gh_oidc_trust.json
  tags               = var.tags
}

# -----------------------------------------------------------------------------
# Minimal deploy policy:
#  - Upload/delete content to S3 (site bucket)
#  - List buckets/objects to drive syncs
#  - Create CloudFront invalidations after deploy
#
# NOTE: For strict least-privilege, pass your bucket ARN and distribution ID
# into this module and scope 'resources' accordingly. Using '*' for simplicity.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "gh_deploy_policy" {
  statement {
    sid    = "S3Deploy"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudFrontInvalidate"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "gh_deploy_policy" {
  name   = "wa-static-site-gh-deploy-policy"
  policy = data.aws_iam_policy_document.gh_deploy_policy.json
}

resource "aws_iam_role_policy_attachment" "gh_deploy_attach" {
  role       = aws_iam_role.gh_actions_deploy.name
  policy_arn = aws_iam_policy.gh_deploy_policy.arn
}
# -----------------------------------------------------------------------------