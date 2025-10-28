terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}


# Issue cert in us-east-1 for CloudFront
resource "aws_acm_certificate" "cf" {
  domain_name               = var.domain_name
  subject_alternative_names = var.san_names
  validation_method         = "DNS"
  tags                      = var.tags

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
}

# Create validation records in Route 53
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cf.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cf" {
  certificate_arn         = aws_acm_certificate.cf.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}
