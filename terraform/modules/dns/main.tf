# Apex A/AAAA aliases
resource "aws_route53_record" "root_a" {
  zone_id = var.zone_id
  name    = var.root_name
  type    = "A"
  alias {
    name                   = var.cf_domain_name
    zone_id                = var.cf_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "root_aaaa" {
  zone_id = var.zone_id
  name    = var.root_name
  type    = "AAAA"
  alias {
    name                   = var.cf_domain_name
    zone_id                = var.cf_hosted_zone_id
    evaluate_target_health = false
  }
}

# www A/AAAA aliases (optional)
resource "aws_route53_record" "www_a" {
  count   = var.enable_www ? 1 : 0
  zone_id = var.zone_id
  name    = "www.${var.root_name}"
  type    = "A"
  alias {
    name                   = var.cf_domain_name
    zone_id                = var.cf_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  count   = var.enable_www ? 1 : 0
  zone_id = var.zone_id
  name    = "www.${var.root_name}"
  type    = "AAAA"
  alias {
    name                   = var.cf_domain_name
    zone_id                = var.cf_hosted_zone_id
    evaluate_target_health = false
  }
}
