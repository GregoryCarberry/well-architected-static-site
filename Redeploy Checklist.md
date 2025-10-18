# 🚀 AWS Well-Architected Static Site — Redeploy Checklist

Use this when returning to the project to quickly rebuild the infrastructure and redeploy the static site.

---

## 1️⃣  Pre-Checks

1. Ensure your AWS CLI is authenticated:

   ```bash
   aws sts get-caller-identity
   ```

   Confirm you see your Account ID and IAM user.

2. Verify that your GitHub repository still contains these secrets:

   * `AWS_REGION` → `eu-west-1`
   * `AWS_ROLE_ARN` → your deploy role ARN (e.g., `arn:aws:iam::412717960006:role/wa-static-site-gh-deploy`)

3. Confirm Terraform variables are set or exist in `terraform.auto.tfvars`:

   ```hcl
   github_owner  = "GregoryCarberry"
   github_repo   = "well-architected-static-site"
   github_branch = "main"
   ```

---

## 2️⃣  Rebuild Infrastructure

Run from the `terraform/` folder:

```bash
terraform init -upgrade
terraform apply -auto-approve \
  -var="github_owner=GregoryCarberry" \
  -var="github_repo=well-architected-static-site" \
  -var="github_branch=main"
```

Terraform will recreate:

* S3 bucket (private, versioned)
* CloudFront distribution (with OAC)
* WAF ACL
* IAM deploy role and OIDC provider

When complete, note the output values:

```bash
terraform output
```

Record:

* **bucket_name**
* **cloudfront_domain_name**
* **cloudfront_distribution_id**

---

## 3️⃣  Verify GitHub Actions CI/CD

1. In GitHub → **Actions → Deploy**, click **Run workflow**.
2. Wait for it to complete (it uploads `site/` to S3 and invalidates CloudFront).
3. Open your CloudFront domain URL — you should see your static site live.

---

## 4️⃣  Optional Enhancements

* Add an **ACM certificate** and **Route 53 alias record** for a custom domain.
* Configure **S3 access logging** and **CloudFront logging** to S3 with lifecycle policies.
* Create a **remote backend** (S3 + DynamoDB) for Terraform state.

---

**Last verified:** *$(date +"%Y-%m-%d")*
