# --- dns.tf (Gestión de Identidad y Seguridad SSL) ---

# 1. Zona Alojada en Route 53
resource "aws_route53_zone" "main" {
  name = var.domain_name
  
  tags = {
    Name = "${var.project_name}-dns-zone"
  }
}

# 2. Solicitud de Certificado SSL (ACM) - ¡GRATIS!
resource "aws_acm_certificate" "moodle_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "www.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-ssl-cert"
  }
}

# 3. Validación DNS del Certificado
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.moodle_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# 4. Confirmación de Validación
resource "aws_acm_certificate_validation" "cert_status" {
  certificate_arn         = aws_acm_certificate.moodle_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# 5. Registros A (Apuntar el dominio al Load Balancer)
resource "aws_route53_record" "root_a" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www_a" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}

# --- [BYTEMIND] Continuidad de Negocio: Registros de Correo Legacy ---

# 1. Registro MX (Correo)
resource "aws_route53_record" "mail_mx" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "MX"
  ttl     = 3600
  records = ["10 mx.buzondecorreo.com."]
}

# 2. Registros TXT (SPF y DKIM)
resource "aws_route53_record" "mail_spf" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 3600
  records = ["v=spf1 include:_spf.buzondecorreo.com ~all"]
}

resource "aws_route53_record" "mail_dkim" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "1764679280052._domainkey"
  type    = "TXT"
  ttl     = 3600
  records = ["v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAicQe9Lk6IWqXvNBQaW6IUmtRbsff7piKWTWV6Qy2wVWNSECkbAirX7B/yjDhwk1E+bzoxrH3V6Xq+Ky0ufZuKNXK OfHnNqB192tPAFNV2ur2ZdxC8PSRalJ2cd/33T0WrDC0Wul+KwkQcSmUWVYYkazSXhJEzhkjWOUqyOdp/w9jkX7mHuZhoXLd2Y6CZ2CoJ6bxUoqSx85Qg1DL8dWtoHL9RnzW75fujxoiz/yeScjVSI3UWzuMmyCjyGqOc+3yJ+Vl4mVTLSQDlDP6BudAaSkOkrkLbHstOwg7URZMMQ9sn1/NcXiUVbByR3V7VSIWYOWS+ZQIDAQAB"]
}

# 3. Registros CNAME (Autodiscovery y Webmail)
resource "aws_route53_record" "mail_autoconfig" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "autoconfig"
  type    = "CNAME"
  ttl     = 3600
  records = ["autoconfig.buzondecorreo.com"]
}

resource "aws_route53_record" "mail_autodiscover" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "autodiscover"
  type    = "CNAME"
  ttl     = 3600
  records = ["autodiscover.buzondecorreo.com"]
}

resource "aws_route53_record" "mail_webmail" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "webmail"
  type    = "CNAME"
  ttl     = 3600
  records = ["buzondecorreo.com"]
}

# 4. Registros de Control de Panel PiensaSolutions (Opcional pero recomendado)
resource "aws_route53_record" "ps_control" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "control"
  type    = "CNAME"
  ttl     = 3600
  records = ["pdc.piensasolutions.com"]
}

resource "aws_route53_record" "ps_panel" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "panel"
  type    = "CNAME"
  ttl     = 3600
  records = ["pdc.piensasolutions.com"]
}
