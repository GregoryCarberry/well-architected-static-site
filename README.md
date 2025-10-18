# ☁️ Well-Architected Static Site (AWS + Terraform)

A fully automated, secure, and cost-efficient static website deployment built on AWS.
This project demonstrates how to apply **AWS Well-Architected Framework** principles using **Terraform** and **GitHub Actions CI/CD**.

---

## 🧩 Overview

**Goal:** Host a production-grade static site with modern DevOps best practices.

**Architecture:**

* **S3 (private)** — hosts static files
* **CloudFront (OAC)** — secure content delivery
* **AWS WAF** — adds managed security protection
* **GitHub Actions** — handles CI/CD (build, deploy, invalidate cache)
* **Terraform IaC** — defines all infrastructure as code

---

## 🏗️ Project Structure

```
well-architected-static-site/
├── terraform/               # Terraform IaC for AWS resources
├── site/                    # Static website files (index.html, assets)
├── .github/workflows/       # GitHub Actions CI/CD workflows
├── CLEANUP_CHECKLIST.md     # Steps to safely tear down resources
├── REDEPLOY_CHECKLIST.md    # Steps to rebuild the project
└── README.md                # (this file)
```

---

## Architecture Diagram

![Architecture Diagram](./architecture_diagram_static_site.md)

---

## 🚀 Key Features

* **Private S3 bucket** with Origin Access Control (OAC)
* **CloudFront CDN** distribution for global delivery
* **AWS WAFv2** with managed rules for security
* **Terraform-managed IAM roles** for GitHub OIDC deploys
* **GitHub Actions CI/CD** automating site sync and cache invalidation
* **Versioned infrastructure** using Terraform modules and remote backend (optional)

---

## 🔧 Setup Summary

1. Configure AWS CLI (`aws configure`).
2. Run Terraform from `/terraform` to provision infrastructure.
3. Add repo secrets:

   * `AWS_ROLE_ARN`
   * `AWS_REGION`
4. Push updates to `/site` → GitHub Actions auto-syncs and invalidates CloudFront.

---

## 🧹 Maintenance

* Use **CLEANUP_CHECKLIST.md** when pausing or decommissioning.
* Use **REDEPLOY_CHECKLIST.md** when returning to rebuild the project.

Both guides include tested commands and safe cleanup procedures for versioned S3 buckets and CloudFront resources.

---

## 🧠 Learning Focus

This project reinforces:

* **Security:** Private access patterns via OAC, IAM least privilege.
* **Reliability:** Infrastructure-as-Code reproducibility.
* **Performance:** Global CDN caching.
* **Operational Excellence:** Automated CI/CD pipelines.
* **Cost Optimization:** Serverless, pay-as-you-go hosting.

---

### ✅ Status

Currently in maintenance-ready state — all infrastructure can be rebuilt using Terraform or safely destroyed with cleanup scripts.

**Author:** Gregory John Carberry
**LinkedIn:** [linkedin.com/in/gregory-carberry](https://www.linkedin.com/in/gregory-carberry/)
**GitHub:** [github.com/GregoryCarberry](https://github.com/GregoryCarberry)

---

**Last verified:** *$(date +"%Y-%m-%d")*
