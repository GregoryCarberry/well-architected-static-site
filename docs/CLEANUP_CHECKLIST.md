# 🧹 AWS Well-Architected Static Site — Cleanup Checklist

Use this when pausing the project to avoid incurring AWS costs. This removes **all runtime infra** (CloudFront, WAF, S3 site & logs, IAM role, OIDC, Route 53 records, ACM cert).  
Your **Terraform state** now lives in an S3 backend with DynamoDB locking; keep that backend unless you explicitly want to remove it too.

---

## 0) Prereqs

- You have `terraform/terraform.auto.tfvars` with:
  ```hcl
  enable_custom_domain = true
  domain_name          = "gjcarberry.uk"
  github_owner  = "GregoryCarberry"
  github_repo   = "well-architected-static-site"
  github_branch = "main"
  ```
- You’re in the repo’s `terraform/` folder and authenticated (`aws sts get-caller-identity`).

---

## 1) Empty versioned S3 buckets (site + logs)

Both buckets are versioned; **all versions and delete markers** must be removed.

### Option A — Console (quickest)
1. S3 → Buckets → `wa-static-site-site-<account_id>` → **Empty bucket**.
2. S3 → Buckets → `wa-static-site-logs-<account_id>` → **Empty bucket**.

### Option B — CLI (WSL/bash)
```bash
SITE=$(terraform output -raw bucket_name)
LOGS="${SITE/-site-/-logs-}"

# helper to purge all versions + delete markers
purge() {
  B="$1"
  while :; do
    V=$(aws s3api list-object-versions --bucket "$B" --query 'Versions[][Key,VersionId]' --output text)
    M=$(aws s3api list-object-versions --bucket "$B" --query 'DeleteMarkers[][Key,VersionId]' --output text)
    [ -z "$V$M" ] && break
    awk 'NF{print}' <<< "$V" | while read -r k v; do aws s3api delete-object --bucket "$B" --key "$k" --version-id "$v" >/dev/null; done
    awk 'NF{print}' <<< "$M" | while read -r k v; do aws s3api delete-object --bucket "$B" --key "$k" --version-id "$v" >/dev/null 2>&1; done
  done
}

purge "$SITE"
purge "$LOGS"
```

---

## 2) Destroy infrastructure (keeps remote state)

From `terraform/`:
```bash
terraform destroy -auto-approve
```

This removes:
- CloudFront distribution (custom domain + cert attached)
- Route 53 A/AAAA (root + www) aliases
- ACM certificate (us-east-1)
- WAF ACL
- S3 **site** and **logs** buckets
- IAM deploy role + policy
- GitHub OIDC provider (if managed here)

> Your **remote state** stays in the S3 backend (recommended).

---

## 3) Optional: remove the backend (state) too

Only do this if you want a totally clean account and are okay losing the state file:

```bash
# S3 state bucket (created manually earlier)
aws s3api delete-bucket --bucket wa-static-site-tfstate-412717960006 --region eu-west-1

# DynamoDB lock table
aws dynamodb delete-table --table-name wa-static-site-tf-locks
```

> If the state bucket isn’t empty, empty it first via console.

---

## 4) Verify all clear

```bash
aws cloudfront list-distributions --query "DistributionList.Items[*].Id"
aws s3 ls | grep wa-static-site
aws wafv2 list-web-acls --scope CLOUDFRONT
aws route53 list-hosted-zones-by-name --dns-name gjcarberry.uk
```

Only unrelated resources should appear.

---

## 5) Notes

- Security headers are managed by a CloudFront **Response Headers Policy**.  
- CSP is temporarily relaxed to allow inline styles; when you move to external CSS we’ll tighten it again.
- GitHub Actions secrets (`AWS_ROLE_ARN`, `AWS_REGION`) can remain as-is.

**Last verified:** 2025-10-19
