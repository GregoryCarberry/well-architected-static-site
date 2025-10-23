# ☁️ Well-Architected Static Site (AWS + Terraform)

A **fully automated, secure, and cost-efficient static website** deployment built on AWS.

This project demonstrates the **AWS Well-Architected Framework** across all five pillars, using **Terraform** and **GitHub Actions CI/CD** to manage a modern static site pipeline.

---

## 🧩 Overview

**Goal:** Build and operate a production-grade static site following AWS best practices for architecture, security, and operations — deployable via a single `terraform apply`.

**Core services:**
- **Amazon S3 (private)** – static file hosting (origin only)
- **Amazon CloudFront (OAC)** – global CDN and TLS termination
- **AWS WAFv2** – managed web security at the edge
- **AWS Route 53** – DNS hosting and certificate validation
- **AWS Certificate Manager (us-east-1)** – SSL certificate for CloudFront
- **GitHub Actions (OIDC)** – continuous deployment via short-lived credentials
- **Terraform (IaC)** – declarative infrastructure provisioning

---

## 🏗️ Project Structure

```
well-architected-static-site/
├── site/
│   ├── index.html                # Landing page
│   ├── 404.html                  # Custom error page
│   └── assets/                   # CSS, JS, and images (cached separately)
│
├── terraform/
│   ├── main.tf                   # CloudFront, S3, WAF, Route 53, IAM, etc.
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Exported values (IDs, ARNs, endpoints)
│   └── backend.tf                # Remote state + DynamoDB locking
│
├── .github/workflows/
│   ├── deploy.yml                # CI/CD pipeline (build → sync → invalidate)
│   └── ci.yml                    # Terraform fmt/validate, TFLint, Checkov
│
├── docs/
│   ├── architecture.png          # Architecture diagram (CloudFront-S3-WAF-CI/CD)
│   ├── CLEANUP_CHECKLIST.md      # Verified teardown steps
│   ├── REDEPLOY_CHECKLIST.md     # Re-provisioning and redeployment steps
│   └── DAILY_TERRAFORM_CYCLE.md  # Terraform steps for cleanup / redeploy
|
└── README.md                     # (this file)
```

---

## 🧭 Architecture Diagram

For details, see [architecture_diagram_static_site.md](./docs/architecture_diagram_static_site.md).

![AWS Well-Architected Static Site Architecture](./docs/architecture.png)

---

## 🚀 Key Features

### 🔐 Security
- **CloudFront OAC** for private S3 origin access (no public buckets)
- **Strict HTTPS enforcement** (`redirect-to-https`)
- **Response Headers Policy**: CSP, HSTS, X-Frame-Options, Referrer-Policy, etc.
- **AWS WAFv2** with managed rule groups (SQLi/XSS/Common Rule Set)
- **IAM least-privilege role** for GitHub OIDC deployments
- **Server-side encryption (AES-256)** on all S3 buckets

### 🛡️ Additional Security Enhancements

- **Modern Response Headers Policy** — Adds robust browser-level protection:
  - `Content-Security-Policy` (strict, no inline scripts or styles)
  - `Strict-Transport-Security`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`
  - Cross-origin isolation headers (`COOP`, `COEP`, `CORP`)  
  - `Permissions-Policy` restricting camera, mic, and geolocation access
- **Public Disclosure Metadata** — Implements standard `.well-known` endpoints:
  - `robots.txt` for crawler guidance  
  - `.well-known/security.txt` for responsible vulnerability disclosure (RFC 9116)
- **Infrastructure Hardening** — Buckets use `force_destroy = true` for safe teardown of versioned data, and lifecycle rules to expire non-current versions.

> Together these measures align the static site with modern web-security benchmarks such as Mozilla Observatory A+ and AWS Well-Architected Security Pillar guidance.


### ⚙️ Reliability
- **Infrastructure-as-Code** (Terraform)
- **State locking** via DynamoDB
- **Versioned S3 buckets**
- **Custom 404 and graceful 403→404 mapping**
- **www → apex redirect** using a CloudFront Function

### ⚡ Performance Efficiency
- **Separate cache policies**:
  - HTML → `CachingDisabled`
  - `/assets/*` → `CachingOptimized`
- **Brotli/Gzip compression** enabled
- **Edge network limited to PriceClass_100** (EU + N. America)
- **Fast invalidation** from CI/CD

### 💰 Cost Optimisation
- Serverless architecture (S3 + CloudFront)
- Logging bucket with lifecycle expiry (90 days)
- Site bucket version expiry (30 days)
- AWS Budget alert with email notifications
- Regional resource placement (eu-west-2)
- Automated teardown via `CLEANUP_CHECKLIST.md`

### 🧠 Operational Excellence
- **GitHub Actions CI/CD** pipeline:
  1. Assumes AWS role via OIDC
  2. Syncs `/site` to S3
  3. Invalidates CloudFront cache
- **Terraform fmt/validate, TFLint & Checkov** run on every push and PR
- Ready for **Athena + Glue** log analytics (planned)
- Full rebuild capability via `REDEPLOY_CHECKLIST.md`

---

## 🔧 Setup Summary

1. Configure AWS CLI:
   ```bash
   aws configure
   ```
2. Deploy infrastructure:
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```
3. Add GitHub secrets:
   - `AWS_ROLE_ARN`
   - `AWS_REGION`
4. Push updates to `/site` → GitHub Actions auto-syncs and invalidates CloudFront.

---

## 📊 Well-Architected Pillar Mapping

| Pillar | Implementation Highlights |
|--------|----------------------------|
| **Security** | OAC, HTTPS, WAFv2, IAM least privilege, encryption, CSP |
| **Reliability** | IaC, versioning, error handling, remote state, DNS validation |
| **Performance Efficiency** | Cache policies, compression, edge selection |
| **Cost Optimisation** | Budgets, lifecycle rules, PriceClass, serverless hosting |
| **Operational Excellence** | CI/CD, Terraform validation, linting, security scans, observability plan |

---

## 🧹 Maintenance

Use:
- **CLEANUP_CHECKLIST.md** – safe teardown of versioned buckets, OAC, CloudFront.
- **REDEPLOY_CHECKLIST.md** – quick rebuild guide after cleanup.

---

## 🧩 Next Steps

- Add **CloudFront Security Headers Policy** as a managed resource.
- Integrate **Athena/Glue** for log analytics dashboards.
- Add **robots.txt** and **sitemap.xml** for SEO readiness.
- Document outputs (`distribution_id`, `site_domain`) for portfolio linkage.

---

## 👤 Author

**Gregory John Carberry**  
[LinkedIn](https://www.linkedin.com/in/gregory-carberry) • [GitHub](https://github.com/GregoryCarberry)

---

**Last verified:** *2025-10-21*
