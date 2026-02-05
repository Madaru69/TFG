output "moodle_url" {
  description = "Enlace directo para acceder a Moodle"
  value       = "http://${aws_lb.app_alb.dns_name}"
}

output "efs_id" {
  description = "ID del Sistema de Archivos EFS para referencia"
  value       = aws_efs_file_system.moodle_efs.id
}
