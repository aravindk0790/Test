# Hosted Zone
data "aws_route53_zone" "this" {
  name         = var.route53_zone
  private_zone = false
}

# Certificates

# Certificate - Main
resource "aws_acm_certificate" "main" {
  domain_name       = var.route53_zone
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_record_main" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  zone_id         = data.aws_route53_zone.this.id
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_record_main : record.fqdn]
}


# Certificate - Main Wildcard
resource "aws_acm_certificate" "main_wildcard" {
  domain_name       = join(".", ["*", var.route53_zone])
  validation_method = "DNS"

  tags = {
    Application = var.tag_application
    Environment = var.tag_environment
    Project     = var.tag_project
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_record_main_wildcard" {
  for_each = {
    for dvo in aws_acm_certificate.main_wildcard.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  zone_id         = data.aws_route53_zone.this.id
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "main_wildcard" {
  certificate_arn         = aws_acm_certificate.main_wildcard.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_record_main_wildcard : record.fqdn]
}
