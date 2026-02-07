output "moodle_url" {
  description = "Enlace seguro para acceder a Moodle"
  value       = "https://${var.domain_name}"
}

output "nameservers" {
  description = "Servidores de nombres que debes copiar a PiensaSolutions"
  value       = aws_route53_zone.main.name_servers
}

output "efs_id" {
  description = "ID del Sistema de Archivos EFS para referencia"
  value       = aws_efs_file_system.moodle_efs.id
}
