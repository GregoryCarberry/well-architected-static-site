# 🚀 AWS Well-Architected Static Site — Redeploy Checklist

Use this to quickly rebuild the project with **remote state (S3 + DynamoDB)**, **custom domain**, **security headers**, and **access logging**.

---

## 1) Pre-checks

1. **AWS CLI auth**
   ```bash
   aws sts get-caller-identity
   ```
   Confirm Account ID prints.

2. **Repo secrets**
   - `AWS_REGION = eu-west-1`
   - `AWS_ROLE_ARN = arn:aws:iam::412717960006:role/wa-static-site-gh-deploy`

3. **terraform.auto.tfvars present**
   ```hcl
   enable_custom_domain = true
   domain_name          = "gjcarberry.uk"
   github_owner  = "GregoryCarberry"
   github_repo   = "well-architected-static-site"
   github_branch = "main"
   ```

4. **Backend exists (created once)**
   - S3 bucket: `wa-static-site-tfstate-412717960006`
   - DynamoDB table: `wa-static-site-tf-locks`

---

## 2) Init + Apply

From the `terraform/` folder:
```bash
terraform init -reconfigure
terraform apply -auto-approve
```

Terraform will create:
- S3 **site** bucket (private, versioned)
- CloudFront distribution (OAC) using your **ACM cert** and **aliases** (`gjcarberry.uk`, `www.gjcarberry.uk`)
- WAF ACL (AWS managed rules)
- CloudFront **Response Headers Policy** (HSTS, CSP, XFO, XCTO, Referrer-Policy, Permissions-Policy)
- **Access logging**:
  - CloudFront → `wa-static-site-logs-<acct>/cloudfront/`
  - S3 server access logs → `…/s3-site/`
- IAM deploy role + policy for GitHub OIDC

Outputs to note:
```bash
terraform output
# bucket_name, cloudfront_domain_name, cloudfront_distribution_id
```

---

## 3) Deploy site content (CI/CD)

Trigger GitHub Actions:
- GitHub → **Actions → deploy → Run workflow**, or
- Commit changes under `site/` to auto-trigger.

Verify:
```bash
curl -I https://gjcarberry.uk
```
You should see `200` and headers:
`strict-transport-security`, `content-security-policy`, `x-frame-options`, `x-content-type-options`, `referrer-policy`, `permissions-policy`.

---

## 4) Confirm logging (after a bit of traffic)

```bash
LOGS=$(terraform output -raw bucket_name | sed 's/-site-/-logs-/')
aws s3 ls "s3://$LOGS/cloudfront/" --recursive
```

---

## 5) Daily workflow tips

- **Pause (end of day)**: follow `CLEANUP_CHECKLIST.md` — empty buckets → `terraform destroy`.
- **Resume (next day)**: `terraform init -reconfigure` → `terraform apply -auto-approve` → trigger **deploy** workflow.

> When you move styles to an external CSS file, tighten CSP by removing `'unsafe-inline'` from `style-src` in the response-headers policy and whitelisting your asset domains.

**Last verified:** 2025-10-19
