```mermaid
graph TD
    subgraph GitHub[GitHub Actions CI/CD]
        A1["Commit / Push to main"] --> A2["Deploy Workflow"]
        A2 --> A3["AssumeRole via OIDC (short-lived creds)"]
        A3 -->|Sync /site → S3| S3Bucket
        A3 -->|Invalidate cache| CFDistribution
    end

    subgraph AWS[AWS Infrastructure]
        S3Bucket[(Private S3 Bucket — Encrypted, Versioned)]
        CFDistribution[CloudFront Distribution — HTTPS + Compression]
        WAF[WAFv2 Managed Rules]
        OAC[Origin Access Control]
        ACM[ACM Certificate (us-east-1)]
        Route53[Route 53 DNS Validation]
    end

    subgraph User[End Users]
        Browser[Browser Request (HTTPS)]
    end

    Browser -->|HTTPS Request| CFDistribution
    CFDistribution -->|Fetch content| S3Bucket
    CFDistribution -->|Uses| OAC
    CFDistribution -->|Protected by| WAF
    CFDistribution -->|TLS cert from| ACM
    ACM -->|Validated via| Route53

    style S3Bucket fill:#f9f9f9,stroke:#ffa500,stroke-width:2px
    style CFDistribution fill:#f9f9f9,stroke:#0088ff,stroke-width:2px
    style WAF fill:#f9f9f9,stroke:#ff4444,stroke-width:2px
    style OAC fill:#f9f9f9,stroke:#888888,stroke-width:2px
    style ACM fill:#f9f9f9,stroke:#44aa44,stroke-width:2px
    style Route53 fill:#f9f9f9,stroke:#bb66ff,stroke-width:2px
    style GitHub fill:#e8f0fe,stroke:#555,stroke-width:1px
    style AWS fill:#fef7e0,stroke:#555,stroke-width:1px
    style User fill:#e6ffe6,stroke:#555,stroke-width:1px
```
