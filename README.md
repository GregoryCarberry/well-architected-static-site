# ☁️ Well-Architected Static Site (AWS + Terraform)

A production-aligned AWS static hosting stack designed and implemented
end-to-end using Terraform and GitHub Actions (OIDC).

This project was built to demonstrate practical cloud engineering
capability --- secure architecture, Infrastructure as Code, CI/CD
automation, regional AWS constraints, and cost governance --- aligned to
the AWS Well-Architected Framework.

> **Primary Region:** eu-west-2 (London)\
> **Global/US-East Constraint:** us-east-1 (ACM, CloudFront, WAF)

------------------------------------------------------------------------

## 🎯 Project Objective

Design, deploy, and operate a secure, reproducible static website
architecture using AWS best practices --- deployable via a single
`terraform apply` and suitable for real-world production environments.

This was intentionally built with production discipline, not just
functionality.

------------------------------------------------------------------------

## 🏗 Architecture Summary

**Core Services Used:**

-   **Amazon S3 (private, eu-west-2)** -- secure static origin with
    logging\
-   **Amazon CloudFront (OAC enabled)** -- global CDN + TLS termination\
-   **AWS WAFv2 (CLOUDFRONT scope)** -- managed threat protection\
-   **AWS Certificate Manager (us-east-1)** -- DNS-validated
    certificate\
-   **Amazon Route 53** -- DNS + ACM validation records\
-   **Terraform (modular IaC)** -- full environment provisioning\
-   **GitHub Actions (OIDC)** -- short-lived credential CI/CD pipeline

------------------------------------------------------------------------

## 🔐 Security & Engineering Decisions

-   S3 bucket fully private (Block Public Access enforced)
-   Origin Access Control (OAC) instead of legacy OAI
-   TLS 1.2+ enforced via CloudFront
-   Modern security headers (CSP, HSTS, Referrer-Policy, etc.)
-   AWS WAF managed rule groups enabled
-   IAM least-privilege role for GitHub OIDC deployment
-   Server-side encryption on all buckets

This reflects a security-first mindset rather than default
configurations.

------------------------------------------------------------------------

## ⚙ Infrastructure & Operational Design

-   Modular Terraform structure (s3, cloudfront, waf, acm, budgets)
-   Split-region provider configuration (eu-west-2 + us-east-1)
-   Randomised S3 suffixing to avoid global name conflicts
-   Remote state & locking ready
-   Deterministic, repeatable deployments
-   Makefile-driven lifecycle management

------------------------------------------------------------------------

## 🚀 CI/CD Implementation

-   GitHub OIDC → AWS assume-role (no long-lived credentials)
-   Automated S3 sync on push
-   Automated CloudFront cache invalidation
-   Validation-ready pipeline (fmt, validate, TFLint, Checkov)

Demonstrates modern cloud deployment practices.

------------------------------------------------------------------------

## 💰 Cost & Governance Controls

-   AWS Budgets with email alerts
-   Lifecycle rules for logs and object versions
-   Serverless architecture (no compute layer)
-   PriceClass_100 for balanced performance vs cost

------------------------------------------------------------------------

## 📊 Well-Architected Pillar Mapping

  Pillar                   Implementation Highlights
  ------------------------ ---------------------------------------------
  Security                 OAC, WAFv2, TLS enforcement, strict headers
  Reliability              IaC, versioning, DNS validation
  Performance              Edge caching, compression
  Cost Optimisation        Budgets, lifecycle rules
  Operational Excellence   CI/CD, modular design, runbooks

------------------------------------------------------------------------

## 🧠 Skills Demonstrated

-   AWS architecture design
-   Terraform Infrastructure as Code
-   CloudFront + S3 secure configuration
-   Regional AWS constraint awareness
-   CI/CD using OIDC federation
-   IAM least-privilege implementation
-   Logging, monitoring, and cost governance

------------------------------------------------------------------------

## 📂 Repository Structure

    well-architected-static-site/
    ├── site/
    ├── terraform/
    ├── .github/workflows/
    ├── docs/
    ├── Makefile
    └── README.md

------------------------------------------------------------------------

## 👤 Author

Gregory John Carberry\
LinkedIn: https://www.linkedin.com/in/gregory-carberry\
GitHub: https://github.com/GregoryCarberry

Last verified: 2026-02-26
