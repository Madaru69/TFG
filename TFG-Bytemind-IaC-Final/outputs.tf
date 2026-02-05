# --- outputs.tf ---

output "alb_dns_name" {
  description = "URL publica del Balanceador de Carga (Entrada a Moodle)"
  value       = aws_lb.app_alb.dns_name
}

output "rds_endpoint" {
  description = "Endpoint de la base de datos (para configurar Moodle)"
  value       = aws_db_instance.moodle_db.address
}
