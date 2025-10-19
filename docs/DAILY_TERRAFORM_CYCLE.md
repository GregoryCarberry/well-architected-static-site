# 🔄 Daily Terraform Cycle — Destroy / Apply

For Gregory John Carberry’s **Well-Architected Static Site** project.

This one-pager covers the quick daily start/stop routine to avoid costs while keeping remote state safe.

---

## 🕓 Morning — Rebuild & Deploy

1️⃣ **Ensure backend exists and AWS CLI is authenticated**
```bash
aws sts get-caller-identity
aws s3 ls | grep tfstate
```

2️⃣ **Rebuild all infra**
```bash
cd ~/well-architected-static-site/terraform
terraform init -reconfigure
terraform apply -auto-approve
```

3️⃣ **Deploy site via GitHub Actions**
- Open your repo → **Actions → deploy → Run workflow**  
  (or commit/push a change under `site/`).

4️⃣ **Confirm site + headers**
```bash
curl -I https://gjcarberry.uk
```
Look for `200 OK` and headers like:  
`strict-transport-security`, `content-security-policy`, `x-frame-options`, `permissions-policy`, etc.

5️⃣ **(Optional) Check CloudFront logs**
```bash
LOGS=$(terraform output -raw bucket_name | sed 's/-site-/-logs-/')
aws s3 ls "s3://$LOGS/cloudfront/" --recursive
```

---

## 🌙 Evening — Clean Up / Pause

1️⃣ **Empty S3 site + logs buckets**
Quickest via AWS Console → Buckets → select → *Empty bucket*.

2️⃣ **Destroy all runtime infra**
```bash
cd ~/well-architected-static-site/terraform
terraform destroy -auto-approve
```

3️⃣ **Verify cleanup**
```bash
aws cloudfront list-distributions --query "DistributionList.Items[*].Id"
aws s3 ls | grep wa-static-site
```

> The S3 backend bucket (`wa-static-site-tfstate-412717960006`) and DynamoDB table (`wa-static-site-tf-locks`) stay untouched—they’re free and preserve state.

---

## 🧠 Notes

- `terraform.auto.tfvars` defines your domain and repo vars, so no need for flags.  
- Remote state ensures a fast, safe rebuild every day.  
- CSP currently allows inline styles; tighten once CSS is externalized.

**Last verified:** 2025-10-19
