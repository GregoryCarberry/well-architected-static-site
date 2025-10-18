# 🧹 AWS Well-Architected Static Site — Cleanup Checklist

Use this when pausing or decommissioning the project to avoid incurring AWS costs.

---

## 1️⃣  Empty the S3 Bucket

The S3 bucket is versioned, so you must remove **all objects, versions, and delete markers**.

### Option A — Management Console

1. Go to **S3 → Buckets**.
2. Find your bucket (`wa-static-site-site-<account_id>`).
3. Click **Empty bucket**, confirm the name, and proceed.

### Option B — CLI (optional future use)

```bash
BUCKET=$(terraform -chdir=terraform output -raw bucket_name)
aws s3api delete-objects \
  --bucket "$BUCKET" \
  --delete "$(aws s3api list-object-versions \
      --bucket "$BUCKET" \
      --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
      --output json)"
```

Repeat for delete markers if needed.

---

## 2️⃣  Destroy Infrastructure

Run from the `terraform/` folder:

```bash
terraform destroy -auto-approve \
  -var="github_owner=GregoryCarberry" \
  -var="github_repo=well-architected-static-site" \
  -var="github_branch=main"
```

This deletes:

* CloudFront distribution
* S3 bucket
* WAF ACL
* IAM deploy role & policy
* OIDC provider (if Terraform created it)

---

## 3️⃣  Optional Manual Cleanup

If Terraform destroy leaves the OIDC provider behind:

```bash
aws iam delete-open-id-connect-provider \
  --open-id-connect-provider-arn arn:aws:iam::<account_id>:oidc-provider/token.actions.githubusercontent.com
```

No cost if left in place.

---

## 4️⃣  Verify All Clear

```bash
aws cloudfront list-distributions --query "DistributionList.Items[*].Id"
aws s3 ls | grep wa-static-site
aws wafv2 list-web-acls --scope CLOUDFRONT
```

All should return empty.

---

## 5️⃣  Pause Notes

When resuming:

```bash
terraform apply -auto-approve \
  -var="github_owner=GregoryCarberry" \
  -var="github_repo=well-architected-static-site" \
  -var="github_branch=main"
```

GitHub Actions secrets (`AWS_ROLE_ARN`, `AWS_REGION`) remain valid, so redeployment is instant.

---

**Last verified:** *$(date +"%Y-%m-%d")*
